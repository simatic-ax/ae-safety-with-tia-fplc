USING System.Timer;


NAMESPACE SimpleConveyor

    CLASS ConveyorController
        VAR PUBLIC
            Inputs : conveyorInputs;
            Outputs : conveyorOutputs;
        END_VAR
        
        VAR PRIVATE
            SystemEnabled       : BOOL := FALSE;
            ConveyorCommand     : BOOL := FALSE;
            ItemCounter         : INT := 0;
            CounterDirection    : BOOL := TRUE;
            CurrentState        : INT := 0; // 0=STOPPED, 1=STARTING, 2=RUNNING, 3=FAULT
            
            // Edge detection
            ItemAtPosB_Old      : BOOL := FALSE;
            StartButton_Old     : BOOL := FALSE;
            StopButton_Old      : BOOL := FALSE;
            SafetyOK_Old        : BOOL := FALSE; 
            
            // Timers
            StartDelay          : OnDelay;
            SafetyLossTimer     : OnDelay; // Timer to monitor safety signal loss

            // Safety monitoring
            SafetyLossDetected  : BOOL := FALSE;
            SafetyRestored      : BOOL := FALSE;
        END_VAR
        
        METHOD PUBLIC Execute
            THIS.CheckSafety();
            THIS.ProcessButtons();
            THIS.HandleStateMachine();
            THIS.ProcessItems();
            THIS.SetOutputs();

            // Store previous safety state
            THIS.SafetyOK_Old := THIS.Inputs.SafetyOK;
        END_METHOD
        
        METHOD PRIVATE CheckSafety
            VAR
                SafetyFalling   : BOOL;
                SafetyRising    : BOOL;
            END_VAR

            // Detect safety signal transitions
            SafetyFalling := NOT THIS.Inputs.SafetyOK AND THIS.SafetyOK_Old;
            SafetyRising := THIS.Inputs.SafetyOK AND NOT THIS.SafetyOK_Old;

            // Monitor safety signal loss
            IF SafetyFalling THEN
                THIS.SafetyLossDetected := TRUE;
                THIS.SafetyLossTimer(signal := TRUE, duration := T#5s); // Start monitoring timer
            END_IF;

            // Check if safety has been restored
            IF SafetyRising THEN
                THIS.SafetyRestored := TRUE;
                THIS.SafetyLossDetected := FALSE;
                THIS.SafetyLossTimer(signal := FALSE);
            END_IF;

            // Basic safety check
            IF THIS.Inputs.SafetyOK  AND NOT THIS.Inputs.MotorFault THEN
                THIS.SystemEnabled := TRUE;
                IF THIS.CurrentState = 3 AND This.SafetyRestored THEN 
                    THIS.CurrentState := 0; // Go to stopped when safety restored
                    THIS.SafetyRestored := FALSE; // Reset flag
                END_IF;
            ELSE
                THIS.SystemEnabled := FALSE;
                THIS.CurrentState := 3; // Fault state
            END_IF;

            // Extended safety loss handling
            IF THIS.SafetyLossTimer.output THEN
                THIS.Outputs.FaultCode := 3; // Extended safety loss fault
            END_IF;
        END_METHOD
        
        METHOD PRIVATE ProcessButtons
            VAR
                StartEdge : BOOL;
                StopEdge : BOOL;
            END_VAR
            
            // Edge detection for buttons
            StartEdge := THIS.Inputs.StartButton AND NOT THIS.StartButton_Old;
            StopEdge := THIS.Inputs.StopButton AND NOT THIS.StopButton_Old;
            THIS.StartButton_Old := THIS.Inputs.StartButton;
            THIS.StopButton_Old := THIS.Inputs.StopButton;
            
            // Start logic: Only if safety OK and system stopped
            IF StartEdge AND THIS.SystemEnabled AND THIS.CurrentState = 0 THEN
                THIS.CurrentState := 1; // Start
            END_IF;
            
            // Stop logic: Always stop if button pressed or safety not OK       
            IF StopEdge OR NOT THIS.SystemEnabled THEN
                THIS.CurrentState := 0; // Stop
                THIS.StartDelay(signal := FALSE); // Reset start timer
            END_IF;
        END_METHOD
        
        METHOD PRIVATE HandleStateMachine
            CASE THIS.CurrentState OF
                0: // STOPPED
                    THIS.ConveyorCommand := FALSE;
                    
                1: // STARTING
                    // Only allow starting if safety is stable
                    IF NOT THIS.SafetyLossDetected THEN
                        THIS.StartDelay(signal := TRUE, duration := T#2S);
                        IF THIS.StartDelay.output THEN
                            THIS.CurrentState := 2; // Running
                            THIS.StartDelay(signal := FALSE);
                        END_IF;
                    ELSE
                        THIS.CurrentState := 0; // Return to stopped if safety unstable
                    END_IF;
                2: // RUNNING
                    THIS.ConveyorCommand := TRUE;
                    
                3: // FAULT
                    THIS.ConveyorCommand := FALSE;
                    // Can only exit fault by fixing safety and pressing start
                    // Additional safety recovery logic
                    IF THIS.SafetyRestored AND THIS.Inputs.SafetyOK THEN
                        // Wait for explicit restart after safety restoration
                        THIS.Outputs.StatusLED_Yellow := TRUE; // Indicate ready for restart
                    END_IF;
            END_CASE;
        END_METHOD
        
        METHOD PRIVATE ProcessItems
            VAR
                ItemEdge : BOOL;
            END_VAR
            
            // Edge detection for item at Position B
            ItemEdge := THIS.Inputs.ItemAtPosB AND NOT THIS.ItemAtPosB_Old;
            THIS.ItemAtPosB_Old := THIS.Inputs.ItemAtPosB;

            // Counter logic - only when RUNNING and item detected
            IF THIS.CurrentState = 2 AND ItemEdge THEN // Running and item detected
                IF THIS.CounterDirection THEN
                    // Counting UP
                    THIS.ItemCounter := THIS.ItemCounter + 1;
                    IF THIS.ItemCounter >= THIS.Inputs.MaxCounterValue THEN
                        THIS.CounterDirection := FALSE; //Switch to count down
                    END_IF;
                ELSE
                    THIS.ItemCounter := THIS.ItemCounter - 1;
                    IF THIS.ItemCounter <= 0 THEN
                        THIS.CounterDirection := TRUE; //Swithc to count up
                    END_IF;
                END_IF;
            END_IF;
        END_METHOD
        
        METHOD PRIVATE SetOutputs
            // Motor control with safety
            THIS.Outputs.ConveyorMotor := THIS.ConveyorCommand AND THIS.SystemEnabled;
            
            // Status LEDs with enhanced safety indication
            THIS.Outputs.StatusLED_Green := (THIS.CurrentState = 2);  // Running = Green
            THIS.Outputs.StatusLED_Red := (THIS.CurrentState = 3) OR THIS.SafetyLossDetected;    // Fault = Red
            THIS.Outputs.StatusLED_Yellow := (THIS.CurrentState = 1) OR (THIS.SafetyRestored AND THIS.CurrentState = 3); // Starting or Ready for Restart = Yellow
            
            // Alarm
            THIS.Outputs.AlarmHorn := (THIS.CurrentState = 3) OR (THIS.SafetyLossDetected AND THIS.SafetyLossTimer.output);
            
            // Status info
            THIS.Outputs.SystemState := THIS.CurrentState;
            THIS.Outputs.ItemCounter := THIS.ItemCounter;
            
            // Fault code assignment
            IF THIS.CurrentState = 3 THEN
                IF THIS.SafetyLossDetected AND THIS.SafetyLossTimer.output THEN
                    THIS.Outputs.FaultCode := 3; // Extended safety loss
                ELSIF NOT THIS.Inputs.SafetyOK THEN
                    THIS.Outputs.FaultCode := 1; // Safety fault
                ELSIF THIS.Inputs.MotorFault THEN
                    THIS.Outputs.FaultCode := 2; // Motor fault
                ELSE
                    THIS.Outputs.FaultCode := 1; // General safety fault
                END_IF;
            ELSE
                THIS.Outputs.FaultCode := 0; // No fault
            END_IF;
        END_METHOD
        
    END_CLASS
END_NAMESPACE