USING Siemens.Simatic.Communication.Ouc;

TYPE connectionResult:
    STRUCT
        connected : BOOL;
        dataReceived : BOOL;
        receiveStatus : WORD;
        data0 : BYTE;
        data1 : BYTE;
        safetySignal : BOOL;
        connectionError : BOOL;
        connectionStatus : WORD;
    END_STRUCT;
END_TYPE
CLASS SafetySignalReceiver
    VAR PRIVATE
        _connectionConfig : ConnectionConfiguration := (
            ConnectionID := WORD#16#1,
            ActiveEstablished := FALSE, 
            LocalPort := UINT#2001,
            ConnectionType := BYTE#16#0B  // TCP
        );
        _connection : Connect;
        _receive : TcpReceive;

        _safetySignal : Bool := FALSE;
        _connected : Bool := FALSE;
        _data : ARRAY[0..1] OF BYTE;  // Buffer for received data

        //Debug variables
        _lastData0 : BYTE;  // For debugging
        _lastData1 : BYTE;  // For debugging
        _receiveStatus : WORD;  // For debugging
        _dataReceived : BOOL;  // For debugging
        _dataEverReceived : BOOL := FALSE; //Track if data has been ever received
    END_VAR
    
    METHOD PUBLIC Execute : Bool
        // Connection management - runs every cycle like in example
        _connection(
            execute := NOT _connected AND NOT _connection.busy,
            connectionID := _connectionConfig.ConnectionID,
            connectionConfiguration := _connectionConfig
        );
        
        IF _connection.done THEN
            _connected := TRUE;
        END_IF;
        
        // Receive data if connected - just like example
        IF _connected THEN
            _receive(
                enable := TRUE,
                connectionID := _connectionConfig.ConnectionID,
                adhocMode := TRUE,  // Use adhoc mode like in the example
                data := _data
            );
            
            // Debug info
            _receiveStatus := _receive.status;
            _dataReceived := _receive.newDataReceived;
            
            // Process data when received
            IF _receive.newDataReceived THEN
                _lastData0 := _data[0];
                _lastData1 := _data[1];
                _safetySignal := (_data[0] > BYTE#0);  // Only checking first byte for now
                _dataEverReceived := TRUE; //Set flag when data is received
                _dataReceived := TRUE; //Current Cycle has data
            ELSE
                _dataReceived := FALSE; //Reset for current cycle
            END_IF;
        END_IF;
        
        Execute := _safetySignal;
    END_METHOD

    METHOD PUBLIC GetDebugInfo : connectionResult
        VAR
            result : connectionResult;
        END_VAR      
        result.connected := _connected;
        result.dataReceived := _dataReceived OR _dataEverReceived;
        result.receiveStatus := _receiveStatus;
        result.data0 := _lastData0;
        result.data1 := _lastData1;
        result.safetySignal := _safetySignal;
        result.connectionError := _connection.error;
        result.connectionStatus := _connection.status;

        GetDebugInfo := result;

    END_METHOD
END_CLASS