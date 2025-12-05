USING SimpleConveyor;
USING Siemens.Simatic.Communication.OUC;

PROGRAM ConveyorControl
    VAR_EXTERNAL
         // Reference to global input I/O variables
         //IO_SafetyOK          : BOOL;
         IO_StartButton       : BOOL;
         IO_StopButton        : BOOL;
         IO_ItemAtPosA        : BOOL;
         IO_ItemAtPosB        : BOOL;
         IO_ConveyorRunning   : BOOL;
         IO_MotorFault        : BOOL;
         IO_MaxCounterValue   : INT;
         
         // Reference to global output I/O variables
         IO_ConveyorMotor     : BOOL;
         IO_StatusLED_Green   : BOOL;
         IO_StatusLED_Red     : BOOL;
         IO_StatusLED_Yellow  : BOOL;
         IO_AlarmHorn         : BOOL;
         IO_SystemState       : INT;
         IO_ItemCounter       : INT;
         IO_FaultCode         : INT;


         //Classes instances reference of the global
         Conveyor : ConveyorController;
         SafetyComm : SafetySignalReceiver;
         debugInfo : connectionResult;
    END_VAR
    VAR 
        FirstCycle : BOOL := TRUE;
    END_VAR

    // // Initialize TCP communications on first cycle
    // IF FirstCycle THEN
    //     SafetyComm.Configure();
    //     FirstCycle := FALSE;
    // END_IF;

    //Get debug info
    debugInfo := SafetyComm.GetDebugInfo(); 
    // Map inputs
    //Conveyor.Inputs.SafetyOK := IO_SafetyOK;
    Conveyor.Inputs.SafetyOK := SafetyComm.Execute(); // Get safety signal via TCP
    Conveyor.Inputs.StartButton := IO_StartButton;
    Conveyor.Inputs.StopButton := IO_StopButton;
    Conveyor.Inputs.ItemAtPosA := IO_ItemAtPosA;
    Conveyor.Inputs.ItemAtPosB := IO_ItemAtPosB;
    Conveyor.Inputs.ConveyorRunning := IO_ConveyorRunning;
    Conveyor.Inputs.MotorFault := IO_MotorFault;
    Conveyor.Inputs.MaxCounterValue := IO_MaxCounterValue;
    
    // Execute conveyor logic
    Conveyor.Execute();
    
    // Map outputs
    IO_ConveyorMotor := Conveyor.Outputs.ConveyorMotor;
    IO_StatusLED_Green := Conveyor.Outputs.StatusLED_Green;
    IO_StatusLED_Red := Conveyor.Outputs.StatusLED_Red;
    IO_StatusLED_Yellow := Conveyor.Outputs.StatusLED_Yellow;
    IO_AlarmHorn := Conveyor.Outputs.AlarmHorn;
    IO_SystemState := Conveyor.Outputs.SystemState;
    IO_ItemCounter := Conveyor.Outputs.ItemCounter;
    IO_FaultCode := Conveyor.Outputs.FaultCode;

END_PROGRAM