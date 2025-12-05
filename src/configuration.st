USING SimpleConveyor;
CONFIGURATION MyConfiguration
    TASK Main(Priority := 1);
    
    PROGRAM P1 WITH Main: ConveyorControl;
        
    VAR_GLOBAL
        // Physical Input I/O

        // Moved from defined Input Card for Simulation
        // IO_StartButton       AT %IX0.1 : BOOL;
        // IO_StopButton        AT %IX0.2 : BOOL;
        // IO_ItemAtPosA        AT %IX0.3 : BOOL;
        // IO_ItemAtPosB        AT %IX0.4 : BOOL;
        // IO_ConveyorRunning   AT %IX0.5 : BOOL;
        // IO_MotorFault        AT %IX0.6 : BOOL;

        IO_StartButton       AT %IX4.1 : BOOL;
        IO_StopButton        AT %IX4.2 : BOOL;
        IO_ItemAtPosA        AT %IX4.3 : BOOL;
        IO_ItemAtPosB        AT %IX4.4 : BOOL;
        IO_ConveyorRunning   AT %IX4.5 : BOOL;
        IO_MotorFault        AT %IX4.6 : BOOL;
        IO_MaxCounterValue   AT %IW2 : INT;

        // Physical Output I/O
        // Moved from defined Output Card for Simulation

        // IO_ConveyorMotor     AT %QX0.0 : BOOL;
        // IO_StatusLED_Green   AT %QX0.2 : BOOL;
        // IO_StatusLED_Red     AT %QX0.3 : BOOL;
        // IO_StatusLED_Yellow  AT %QX0.4 : BOOL;
        // IO_AlarmHorn         AT %QX0.5 : BOOL;

        IO_ConveyorMotor     AT %QX8.0 : BOOL;
        IO_StatusLED_Green   AT %QX8.2 : BOOL;
        IO_StatusLED_Red     AT %QX8.3 : BOOL;
        IO_StatusLED_Yellow  AT %QX8.4 : BOOL;
        IO_AlarmHorn         AT %QX8.5 : BOOL;
        IO_SystemState       AT %QW2 : INT;
        IO_ItemCounter       AT %QW4 : INT;
        IO_FaultCode         AT %QW6 : INT;

        // Conveyor instance
        Conveyor : ConveyorController;

        //Safety communication instance
        SafetyComm : SafetySignalReceiver;

        //debug Instance

        debugInfo : connectionResult;
END_VAR
END_CONFIGURATION