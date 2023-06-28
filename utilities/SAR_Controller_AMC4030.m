classdef SAR_Controller_AMC4030 < handle
    properties
        COMPort                 % COM port number of AMC4030
        patience = 10           % Number of attempts for movement in any direction before giving up, default = 10
        
        hor_speed_mms = 20      % Speed of horizontal movement in mm/s
        ver_speed_mms = 20      % Speed of vertical movement in mm/s
        rot_speed_degs = 20     % Speed of rotational movement in deg/s
        
        hor_speed_max_mms = 50  % Speed of horizontal movement in mm/s
        ver_speed_max_mms = 50  % Speed of vertical movement in mm/s
        rot_speed_max_degs = 50 % Speed of rotational movement in deg/s
        
        curr_hor_mm = 0         % Current horizontal position
        curr_ver_mm = 0         % Current vertical position
        curr_rot_deg = 0        % Current rotational position
        
        isConnected = false     % Boolean whether or not the AMC4030 device is connected
    end
    
    methods
        function obj = SAR_Controller_AMC4030(COMPort_In)
            % Note:
            % Horizontal    : X-Axis on AMC4030
            % Veritcal      : Y-Axis on AMC4030
            % Rotational    : Z-Axis on AMC4030
            
            if Connect(obj,COMPort_In) ~= 1
                warning("AMC4030 not connected! Please try calling Connect(COMPort) with another COMPort!")
            else
                obj.COMPort = COMPort_In;
            end
        end
        
        function err = Connect(obj,COMPort)
            % Outputs
            %   1   :   Succesful Connection
            %   -1  :   Error in Connection
            
            % Load the AMC4030 Library
            if ~libisloaded('AMC4030')
                loadlibrary('AMC4030.dll', @ComInterfaceHeader);
            end
            
            % Establish the communication
            calllib('AMC4030','COM_API_SetComType',2);
            for ii = 1:3
                err = calllib('AMC4030','COM_API_OpenLink',COMPort,115200);
                if libisloaded('AMC4030') && err == 1
                    obj.isConnected = true;
                    return;
                end
                disp(ii + "th Connection Failure");
            end
            
            err = -1;
            obj.isConnected = false;
        end
        
        function [err,wait_time] = Move_Horizontal(obj,hor_move_mm)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            % Do the movement using the AMC4030 Controller
            if hor_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == Move_AMC4030(0,hor_move_mm,obj.hor_speed_mms)
                        break;
                    else
                        disp(ii + "th Horizontal Movement Failure")
                        if ii == obj.patience
                            disp("Horizontal Movement of " + hor_move_mm + " mm Failed!")
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_hor_mm = obj.curr_hor_mm + hor_move_mm;
                err = 1;
                wait_time = abs(hor_move_mm/obj.hor_speed_mms);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Vertical(obj,ver_move_mm)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            % Do the movement using the AMC4030 Controller
            if ver_move_mm ~= 0
                for ii = 1:obj.patience
                    if 1 == Move_AMC4030(1,ver_move_mm,obj.ver_speed_mms)
                        break;
                    else
                        disp(ii + "th Vertical Movement Failure")
                        if ii == obj.patience
                            disp("Vertical Movement of " + ver_move_mm + " mm Failed!")
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_ver_mm = obj.curr_ver_mm + ver_move_mm;
                err = 1;
                wait_time = abs(ver_move_mm/obj.ver_speed_mms);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function [err,wait_time] = Move_Rotational(obj,rot_move_deg)
            % Outputs
            %   1   :   Successful Movement
            %   0   :   No Movement Required
            %   -1  :   Error in Movement
            
            wait_time = 0;
            
            % Do the movement using the AMC4030 Controller
            if rot_move_deg ~= 0
                for ii = 1:obj.patience
                    if 1 == Move_AMC4030(2,rot_move_deg,obj.rot_speed_degs)
                        break;
                    else
                        disp(ii + "th Rotational Movement Failure")
                        if ii == obj.patience
                            disp("Rotational Movement of " + rot_move_deg + " deg Failed!")
                            err = -1;
                            return;
                        end
                    end
                end
                
                obj.curr_rot_deg = obj.curr_rot_deg + rot_move_deg;
                err = 1;
                wait_time = abs(rot_move_deg/obj.rot_speed_degs);
                return;
            else
                err = 0;
                return;
            end
        end
        
        function err = Move_AMC4030(obj,axisNum,distance_mm,speed_mmps)
            if ~obj.isConnected
                error("AMC4030 Must Be Connected to Move!!")
            end
            err = calllib('AMC4030','COM_API_Jog',axisNum,distance_mm,speed_mmps);
            % Example call to move 'x' axis to '30 mm' at '20 mm/s'
            % err = calllib('AMC4030','COM_API_Jog',0,30,20);
        end
        
        function err = Home_All(obj,isHome_Hor,isHome_Ver,isHome_Rot)
            if ~obj.isConnected
                error("AMC4030 Must Be Connected to Home!!")
            end
            err = calllib('AMC4030','COM_API_Home',isHome_Hor,isHome_Ver,isHome_Rot);
        end
        
        function err = Stop_All(obj)
            err = calllib('AMC4030','COM_API_StopAll');
        end
    end
    
    methods(Static)
    end
end