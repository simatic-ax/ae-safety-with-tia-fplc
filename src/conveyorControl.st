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
            CurrentState        : currentState;
            LatchedFaultCode    : faultcode := faultcode#NO_FAULT;
            
            // Previous sensor states prevent a held input from counting every cycle.
            ItemAtPosA_Old      : BOOL := FALSE;
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
                IF NOT THIS.Inputs.SafetyOK THEN
                    THIS.LatchedFaultCode := faultcode#GENERAL_SAFETY_FAULT;
                ELSIF THIS.Inputs.MotorFault THEN
                    THIS.LatchedFaultCode := faultcode#MOTOR_FAULT;
                END_IF;
            END_IF;

            // Extended safety loss handling
            IF THIS.SafetyLossTimer.output THEN
                THIS.LatchedFaultCode := faultcode#EXTENDED_SAFETY_LOSS;
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
                            THIS.LatchedFaultCode := faultcode#NO_FAULT;
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
                ItemAtPosAEdge : BOOL;
                ItemAtPosBEdge : BOOL;
            END_VAR
            
            // Count each sensor's rising edge once, even if its input stays high.
            ItemAtPosAEdge := THIS.Inputs.ItemAtPosA AND NOT THIS.ItemAtPosA_Old;
            ItemAtPosBEdge := THIS.Inputs.ItemAtPosB AND NOT THIS.ItemAtPosB_Old;

            // Track inputs while stopped too, so a held sensor is not counted on start.
            THIS.ItemAtPosA_Old := THIS.Inputs.ItemAtPosA;
            THIS.ItemAtPosB_Old := THIS.Inputs.ItemAtPosB;

            // Sensor events affect the item count only while the conveyor is running.
            IF THIS.CurrentState = 2 THEN
                THIS.ItemCounter := UpdateItemCounter(
                    currentCount := THIS.ItemCounter,
                    maxCounterValue := THIS.Inputs.MaxCounterValue,
                    itemAtPosAEdge := ItemAtPosAEdge,
                    itemAtPosBEdge := ItemAtPosBEdge
                );
            END_IF;
        END_METHOD
        
        METHOD PRIVATE SetOutputs
            // Motor control with safety
            THIS.Outputs.ConveyorMotor := THIS.ConveyorCommand AND THIS.SystemEnabled;
            
            // Status LEDs with enhanced safety indication
            THIS.Outputs.StatusLED_Green := (THIS.CurrentState = 2);  // Running = Green
            THIS.Outputs.StatusLED_Red := (THIS.CurrentState = 0) OR (THIS.CurrentState = 3) OR THIS.SafetyLossDetected;
            THIS.Outputs.StatusLED_Yellow := (THIS.CurrentState = 1) OR (THIS.SafetyRestored AND THIS.CurrentState = 3); // Starting or Ready for Restart = Yellow
            
            // Alarm
            THIS.Outputs.AlarmHorn := THIS.LatchedFaultCode <> faultcode#NO_FAULT;
            
            // Status info
            THIS.Outputs.SystemState := THIS.CurrentState;
            THIS.Outputs.ItemCounter := THIS.ItemCounter;
            
            THIS.Outputs.FaultCode := THIS.LatchedFaultCode;
        END_METHOD
        
    END_CLASS

    FUNCTION UpdateItemCounter : INT
        VAR_INPUT
            currentCount : INT;
            maxCounterValue : INT;
            itemAtPosAEdge : BOOL;
            itemAtPosBEdge : BOOL;
        END_VAR
        VAR
            boundedCount : INT;
            effectiveMaximum : INT;
        END_VAR

        // Treat an invalid negative maximum as an empty counter range.
        effectiveMaximum := maxCounterValue;
        IF effectiveMaximum < 0 THEN
            effectiveMaximum := 0;
        END_IF;

        // Keep the existing count inside the configured range, including after a limit change.
        boundedCount := currentCount;
        IF boundedCount < 0 THEN
            boundedCount := 0;
        ELSIF boundedCount > effectiveMaximum THEN
            boundedCount := effectiveMaximum;
        END_IF;

        // Opposite sensor events in the same cycle cancel each other.
        IF itemAtPosAEdge AND NOT itemAtPosBEdge THEN
            IF boundedCount < effectiveMaximum THEN
                boundedCount := boundedCount + 1;
            END_IF;
        ELSIF itemAtPosBEdge AND NOT itemAtPosAEdge THEN
            IF boundedCount > 0 THEN
                boundedCount := boundedCount - 1;
            END_IF;
        END_IF;

        UpdateItemCounter := boundedCount;
    END_FUNCTION
END_NAMESPACE