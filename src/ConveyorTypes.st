NAMESPACE SimpleConveyor

    TYPE conveyorInputs: 
        STRUCT
            SafetyOK          : BOOL; // Single safety signal from safety relay line
            StartButton       : BOOL; // Manual start button
            StopButton        : BOOL; // Manual stop button
            ItemAtPosA        : BOOL; // Sensor: Item at Position A
            ItemAtPosB        : BOOL; // Sensor: Item at Position B
            ConveyorRunning   : BOOL; // Feedback: Motor running
            MotorFault        : BOOL; // Motor fault signal
            MaxCounterValue   : INT := 10; // Maximum counter value
        END_STRUCT;
    END_TYPE

    TYPE conveyorOutputs: 
        STRUCT
            ConveyorMotor     : BOOL; // Conveyor motor control
            StatusLED_Green   : BOOL; // System OK indicator
            StatusLED_Red     : BOOL; // System fault indicator
            StatusLED_Yellow  : BOOL; // System warning/starting
            AlarmHorn         : BOOL; // Safety alarm
            SystemState       : INT; // Current system state
            ItemCounter       : INT; // Current item counter
            FaultCode         : INT; // Active fault code
        END_STRUCT;
    END_TYPE
    
END_NAMESPACE