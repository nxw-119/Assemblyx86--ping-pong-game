.MODEL SMALL

.STACK 100

.DATA
    
    WINDOW_WIDTH DW 140h                
    WINDOW_HEIGHT DW 0C8h               
    WINDOW_BOUNDS DW 6                  

    
    TIME_AUX DB 0                       
    
    GAME_ACTIVE DB 1                
    EXITING_GAME DB 0
    WINNER_INDEX DB 0                    
    CURRENT_SCENE DB 0                   
    
    
    ; ball varaibles
    BALL_ORIGINAL_X DW 0A0h             
    BALL_ORIGINAL_Y DW 64h              
    BALL_X DW 0Ah                        
    BALL_Y DW 0Ah                      
    
    BALL_SIZE DW 06h                    
    BALL_VELOCITY_X DW 05h              
    BALL_VELOCITY_Y DW 02h              

    ; left paddle 
    PADDLE_LEFT_X DW 0Ah              
    PADDLE_LEFT_Y DW 0Ah               
    
    
    ; right paddle 
    PADDLE_RIGHT_X DW 130h              
    PADDLE_RIGHT_Y DW 0Ah               

    ; paddles width , height , velocity 
    PADDLE_WIDTH DW 05h                 
    PADDLE_HEIGHT DW 1Fh                
    PADDLE_VELOCITY DW 0Fh               
    
    PLAYER_ONE_POINTS DB 0              
    PLAYER_TWO_POINTS DB 0              
    
    TEXT_PLAYER_ONE DB 'PLAYER 1: ' , '$'
    TEXT_PLAYER_TWO DB 'PLAYER 2: ' , '$'
    
    TEXT_PLAYER_ONE_POINTS DB '0','$'    
    TEXT_PLAYER_TWO_POINTS DB '0','$'    

    ; GAME OVER PAGE TEXT     
    TEXT_GAME_OVER_TITLE DB '### GAME  OVER ###','$' 
    TEXT_GAME_OVER_WINNER DB 'Player 0 won','$' 
    TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again','$' 
    TEXT_GAME_OVER_MAIN_MENU DB 'Press E to exit to main menu','$' 
    
    ; MAIN MENU PAGE TEXT 
    TEXT_MAIN_MENU_TITLE DB '*****  MAIN  MENU  *****','$' 
    TEXT_MAIN_MENU_STARTPLAYING DB 'START PLAYING - S KEY','$' 
    TEXT_MAIN_MENU_EXIT DB 'EXIT GAME - E KEY','$' 


.CODE 
     

    ; main prosedure 
    MAIN PROC FAR
    .STARTUP

        CALL CLEAR_SCREEN               
        
        CHECK_TIME:                      ;time checking loop
            CMP EXITING_GAME,01h
            JE START_EXIT_PROCESS
            
            CMP CURRENT_SCENE,00h
            JE SHOW_MAIN_MENU
            
            CMP GAME_ACTIVE,00h
            JE SHOW_GAME_OVER
            
            MOV AH,2Ch                   
            INT 21h                      
            
            CMP DL,TIME_AUX              
            JE CHECK_TIME                
            

            ;if it reaches this point, it's because the time has passed
             MOV TIME_AUX,DL            
             CALL CLEAR_SCREEN          

            CALL MOVE_BALL              
            CALL DRAW_BALL              

            CALL MOVE_PADDLES           
            CALL DRAW_PADDLES           
            
            CALL DRAW_UI               
             
            JMP CHECK_TIME              ;after everything check time again
            
            SHOW_GAME_OVER:
                CALL DRAW_GAME_OVER_MENU
                JMP CHECK_TIME
                
            SHOW_MAIN_MENU:
                CALL DRAW_MAIN_MENU
                JMP CHECK_TIME
                
            START_EXIT_PROCESS:
                CALL EXIT2
        RET
    MAIN ENDP

    
    ; movement of the ball procedure 
    MOVE_BALL PROC NEAR                 

;       Move the ball horizontally
        MOV AX,BALL_VELOCITY_X    
        ADD BALL_X,AX                   
        
      
        MOV AX,WINDOW_BOUNDS
        CMP BALL_X,AX                    
        JL GIVE_POINT_TO_PLAYER_TWO      
        
    
        MOV AX,WINDOW_WIDTH
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_X,AX                  
        JG GIVE_POINT_TO_PLAYER_ONE     
        JMP MOVE_BALL_VERTICALLY
        
        GIVE_POINT_TO_PLAYER_ONE:        
            INC PLAYER_ONE_POINTS       
            CALL RESET_BALL_POSITION     
            
            CALL UPDATE_TEXT_PLAYER_ONE_POINTS 
            
            CMP PLAYER_ONE_POINTS,05h   
            JGE GAME_OVER                
            RET
        
        GIVE_POINT_TO_PLAYER_TWO:        
            INC PLAYER_TWO_POINTS     
            CALL RESET_BALL_POSITION     
            
            CALL UPDATE_TEXT_PLAYER_TWO_POINTS 
            
            CMP PLAYER_TWO_POINTS,05h  
            JGE GAME_OVER                
            RET
            
            
        GAME_OVER:                       
            CMP PLAYER_ONE_POINTS,05h    
            JNL WINNER_IS_PLAYER_ONE     
            JMP WINNER_IS_PLAYER_TWO    
            
            WINNER_IS_PLAYER_ONE:
                MOV WINNER_INDEX,01h     
                JMP CONTINUE_GAME_OVER
            WINNER_IS_PLAYER_TWO:
                MOV WINNER_INDEX,02h     
                JMP CONTINUE_GAME_OVER
                
            CONTINUE_GAME_OVER:
                MOV PLAYER_ONE_POINTS,00h   
                MOV PLAYER_TWO_POINTS,00h  
                CALL UPDATE_TEXT_PLAYER_ONE_POINTS
                CALL UPDATE_TEXT_PLAYER_TWO_POINTS
                MOV GAME_ACTIVE,00h            
                RET 

;       Move the ball vertically        
        MOVE_BALL_VERTICALLY:       
            MOV AX,BALL_VELOCITY_Y
            ADD BALL_Y,AX             
        

        MOV AX,WINDOW_BOUNDS
        CMP BALL_Y,AX                    
        JL NEG_VELOCITY_Y                


        
        MOV AX,WINDOW_HEIGHT    
        SUB AX,BALL_SIZE
        SUB AX,WINDOW_BOUNDS
        CMP BALL_Y,AX                    
        JG NEG_VELOCITY_Y                
        

        
        MOV AX,BALL_X
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_RIGHT_X
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE  
        
        MOV AX,PADDLE_RIGHT_X
        ADD AX,PADDLE_WIDTH
        CMP BALL_X,AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE  
        
        MOV AX,BALL_Y
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_RIGHT_Y
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE  
        
        MOV AX,PADDLE_RIGHT_Y
        ADD AX,PADDLE_HEIGHT
        CMP BALL_Y,AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE  
        


        JMP NEG_VELOCITY_X


        CHECK_COLLISION_WITH_LEFT_PADDLE:
        
        
        
        MOV AX,BALL_X
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_LEFT_X
        JNG EXIT_COLLISION_CHECK  
        
        MOV AX,PADDLE_LEFT_X
        ADD AX,PADDLE_WIDTH
        CMP BALL_X,AX
        JNL EXIT_COLLISION_CHECK  
        
        MOV AX,BALL_Y
        ADD AX,BALL_SIZE
        CMP AX,PADDLE_LEFT_Y
        JNG EXIT_COLLISION_CHECK  
        
        MOV AX,PADDLE_LEFT_Y
        ADD AX,PADDLE_HEIGHT
        CMP BALL_Y,AX
        JNL EXIT_COLLISION_CHECK  
        

        
        JMP NEG_VELOCITY_X
        
        NEG_VELOCITY_Y:
            NEG BALL_VELOCITY_Y   
            RET
        NEG_VELOCITY_X:
            NEG BALL_VELOCITY_X             
            RET                              
            
        EXIT_COLLISION_CHECK:
            RET

    MOVE_BALL ENDP
    
    

    MOVE_PADDLES PROC NEAR               
        
;       Left paddle movement
        
        
        MOV AH,01h
        INT 16h
        JZ CHECK_RIGHT_PADDLE_MOVEMENT 
        
        
        MOV AH,00h
        INT 16h
        
        ;if it is 'w' or 'W' move up
        CMP AL,77h ;'w'
        JE MOVE_LEFT_PADDLE_UP
        CMP AL,57h ;'W'
        JE MOVE_LEFT_PADDLE_UP
        
        ;if it is 's' or 'S' move down
        CMP AL,73h ;'s'
        JE MOVE_LEFT_PADDLE_DOWN
        CMP AL,53h ;'S'
        JE MOVE_LEFT_PADDLE_DOWN
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
        MOVE_LEFT_PADDLE_UP:
            MOV AX,PADDLE_VELOCITY
            SUB PADDLE_LEFT_Y,AX
            
            MOV AX,WINDOW_BOUNDS
            CMP PADDLE_LEFT_Y,AX
            JL FIX_PADDLE_LEFT_TOP_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT
            
            FIX_PADDLE_LEFT_TOP_POSITION:
                MOV PADDLE_LEFT_Y,AX
                JMP CHECK_RIGHT_PADDLE_MOVEMENT
            
        MOVE_LEFT_PADDLE_DOWN:
            MOV AX,PADDLE_VELOCITY
            ADD PADDLE_LEFT_Y,AX
            MOV AX,WINDOW_HEIGHT
            SUB AX,WINDOW_BOUNDS
            SUB AX,PADDLE_HEIGHT
            CMP PADDLE_LEFT_Y,AX
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT
            
            FIX_PADDLE_LEFT_BOTTOM_POSITION:
                MOV PADDLE_LEFT_Y,AX
                JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
        
;       Right paddle movement
        CHECK_RIGHT_PADDLE_MOVEMENT:
        
            ;if it is 'o' or 'O' move up
            CMP AL,6Fh ;'o'
            JE MOVE_RIGHT_PADDLE_UP
            CMP AL,4Fh ;'O'
            JE MOVE_RIGHT_PADDLE_UP
            
            ;if it is 'l' or 'L' move down
            CMP AL,6Ch ;'l'
            JE MOVE_RIGHT_PADDLE_DOWN
            CMP AL,4Ch ;'L'
            JE MOVE_RIGHT_PADDLE_DOWN
            JMP EXIT_PADDLE_MOVEMENT
            

            MOVE_RIGHT_PADDLE_UP:
                MOV AX,PADDLE_VELOCITY
                SUB PADDLE_RIGHT_Y,AX
                
                MOV AX,WINDOW_BOUNDS
                CMP PADDLE_RIGHT_Y,AX
                JL FIX_PADDLE_RIGHT_TOP_POSITION
                JMP EXIT_PADDLE_MOVEMENT
                
                FIX_PADDLE_RIGHT_TOP_POSITION:
                    MOV PADDLE_RIGHT_Y,AX
                    JMP EXIT_PADDLE_MOVEMENT
            
            MOVE_RIGHT_PADDLE_DOWN:
                MOV AX,PADDLE_VELOCITY
                ADD PADDLE_RIGHT_Y,AX
                MOV AX,WINDOW_HEIGHT
                SUB AX,WINDOW_BOUNDS
                SUB AX,PADDLE_HEIGHT
                CMP PADDLE_RIGHT_Y,AX
                JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
                JMP EXIT_PADDLE_MOVEMENT
                
                FIX_PADDLE_RIGHT_BOTTOM_POSITION:
                    MOV PADDLE_RIGHT_Y,AX
                    JMP EXIT_PADDLE_MOVEMENT
        
        EXIT_PADDLE_MOVEMENT:
        
            RET
        
    MOVE_PADDLES ENDP

    

        
        
    RESET_BALL_POSITION PROC NEAR       

        MOV AX,BALL_ORIGINAL_X          
        MOV BALL_X,AX                   

        MOV AX,BALL_ORIGINAL_Y
        MOV BALL_Y,AX                   

        RET
    RESET_BALL_POSITION ENDP

   
    
;procedure to draw the ball
    DRAW_BALL PROC NEAR                 

        MOV CX,BALL_X                   
        MOV DX,BALL_Y                   

        DRAW_BALL_HORIZONTAL:
            MOV AH,0Ch                  ;write 
            MOV AL,09h                  ; dark blue 
            MOV BH,00h                  
            INT 10h                     

            INC CX                      
            MOV AX,CX                   
            SUB AX,BALL_X       
            CMP AX,BALL_SIZE            
            JNG DRAW_BALL_HORIZONTAL

            MOV CX,BALL_X               
            INC DX                      
            MOV AX,DX                   
            SUB AX,BALL_Y                   
            CMP AX,BALL_SIZE            
            JNG DRAW_BALL_HORIZONTAL

        RET
    DRAW_BALL ENDP

    

    DRAW_PADDLES PROC NEAR

        MOV CX,PADDLE_LEFT_X            
        MOV DX,PADDLE_LEFT_Y            

; left paddle 
        DRAW_PADDLE_LEFT_HORIZONTAL:
            MOV AH,0Ch                  
            MOV AL,0Dh                  
            MOV BH,00h                  
            INT 10h                     
            
            INC CX                      
            MOV AX,CX                   
            SUB AX,PADDLE_LEFT_X        
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_LEFT_HORIZONTAL

            MOV CX,PADDLE_LEFT_X        
            INC DX                      
            MOV AX,DX                   
            SUB AX,PADDLE_LEFT_Y                    
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_LEFT_HORIZONTAL

            MOV CX,PADDLE_RIGHT_X       
            MOV DX,PADDLE_RIGHT_Y       

            
; right paddle
        DRAW_PADDLE_RIGHT_HORIZONTAL:
            MOV AH,0Ch                  
            MOV AL,0Dh                  
            MOV BH,00h                  
            INT 10h                     

            INC CX                      
            MOV AX,CX                   
            SUB AX,PADDLE_RIGHT_X       
            CMP AX,PADDLE_WIDTH
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL

            MOV CX,PADDLE_RIGHT_X       
            INC DX                      
            MOV AX,DX                   
            SUB AX,PADDLE_RIGHT_Y                   
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_PADDLE_RIGHT_HORIZONTAL

        RET
    DRAW_PADDLES ENDP
    
    
    
    DRAW_UI PROC NEAR
    
    ;PRINT  PLAYER 1 ON SCREEN 
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,01h                      
        MOV DL,03h                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_PLAYER_ONE    
        INT 21h   
        
    ;PRINT PLAYER 2 ON SCREEN 
        
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,01h                      
        MOV DL,1Dh                      
        MOV BL,09H 
        INT 10h  
        
                        
        
        MOV AH,09h                       
        LEA DX,TEXT_PLAYER_TWO    
        INT 21h   
        
    
    
        
     ;PRINT points of player one
        
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,03h                       
        MOV DL,06h                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_PLAYER_ONE_POINTS    
        INT 21h                          
        
       
 ;     PRINT  points player two 
        
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,03h                        
        MOV DL,20h                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_PLAYER_TWO_POINTS    
        INT 21h                          
        
        RET
    DRAW_UI ENDP
    
    
    
    UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
        
        XOR AX,AX
        MOV AL,PLAYER_ONE_POINTS 
        
        
        ADD AL,30h                       
        MOV [TEXT_PLAYER_ONE_POINTS],AL
        
        RET
    UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
    
    
    
    
    
    UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
        
        XOR AX,AX
        MOV AL,PLAYER_TWO_POINTS 
        
       
        ADD AL,30h                       
        MOV [TEXT_PLAYER_TWO_POINTS],AL
        
        RET
    UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
    
    
    
    
    
    DRAW_GAME_OVER_MENU PROC NEAR        
        
        CALL CLEAR_SCREEN                

;       Shows the menu title
        MOV AH,02h                       
        MOV BH,00h                      
        MOV DH,04h                       
        MOV DL,0Ah                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_GAME_OVER_TITLE      
        INT 21h                          

;       Shows the winner
        MOV AH,02h                      
        MOV BH,00h                       
        MOV DH,06h                       
        MOV DL,0Dh                      
        INT 10h                          
        
        CALL UPDATE_WINNER_TEXT
        
        MOV AH,09h                       
        LEA DX,TEXT_GAME_OVER_WINNER     
        INT 21h                          
        
;       play again message
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,0Ah                        
        MOV DL,08h                       
        INT 10h                          

        MOV AH,09h                       
        LEA DX,TEXT_GAME_OVER_PLAY_AGAIN      
        INT 21h                          
        
 ;   GOES MAIN menu 
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,0Ch                       
        MOV DL,08h                       
        INT 10h                          

        MOV AH,09h                       
        LEA DX,TEXT_GAME_OVER_MAIN_MENU       
        INT 21h                          
        
;       Waits for a key press
        MOV AH,00h
        INT 16h

;       If the key is either 'R' or 'r', restart the game       
        CMP AL,'R'
        JE RESTART_GAME
        CMP AL,'r'
        JE RESTART_GAME
;       If the key is either 'E' or 'e', exit to main menu
        CMP AL,'E'
        JE EXIT_TO_MAIN_MENU
        CMP AL,'e'
        JE EXIT_TO_MAIN_MENU
        RET
        
        RESTART_GAME:
            MOV GAME_ACTIVE,01h
            RET
        
        EXIT_TO_MAIN_MENU:
            MOV GAME_ACTIVE,00h
            MOV CURRENT_SCENE,00h
            RET
            
    DRAW_GAME_OVER_MENU ENDP
    
    
    
    
    DRAW_MAIN_MENU PROC NEAR
        
        CALL CLEAR_SCREEN
        
;       Shows the menu title
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,05h                       
        MOV DL,08h                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_MAIN_MENU_TITLE      
        INT 21h                          
        
        
        ;       Shows the START PLAYING message
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,0Ah                       
        MOV DL,0Ah                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_MAIN_MENU_STARTPLAYING      
        INT 21h                          
        

;       Shows the exit message
        MOV AH,02h                       
        MOV BH,00h                       
        MOV DH,0Dh                       
        MOV DL,0Ah                       
        INT 10h                          
        
        MOV AH,09h                       
        LEA DX,TEXT_MAIN_MENU_EXIT      
        INT 21h                            
        
        MAIN_MENU_WAIT_FOR_KEY:
;       Waits for a key press
            MOV AH,00h
            INT 16h
        
;       Check whick key was pressed
            CMP AL,'S'
            JE START_PLAYING
            CMP AL,'s'
            JE START_PLAYING
            
            CMP AL,'E'
            JE EXIT2
            CMP AL,'e'
            JE EXIT2
            JMP MAIN_MENU_WAIT_FOR_KEY
            
        START_PLAYING:
            MOV CURRENT_SCENE,01h
            MOV GAME_ACTIVE,01h
            RET
        
       
        
        EXIT_GAME:
            MOV EXITING_GAME,01h
            RET

    DRAW_MAIN_MENU ENDP
    
    
    
    UPDATE_WINNER_TEXT PROC NEAR
        
        MOV AL,WINNER_INDEX              
        ADD AL,30h                       
        MOV [TEXT_GAME_OVER_WINNER+7],AL 
        
        RET
    UPDATE_WINNER_TEXT ENDP
    
    
    EXIT2:                              
        MOV AH,00h                      
        MOV AL,02h                      
        INT 10h 
        MOV AH, 4Ch                     
        MOV AL, 00h
        INT 21H
    CLEAR_SCREEN PROC NEAR              

        MOV AH,00h                      
        MOV AL,13h                      
        INT 10h                         

        MOV AH,0Bh                      
        MOV BH,00h                      
        MOV BL,07h                      
        INT 10h                         

        RET
    CLEAR_SCREEN ENDP
     
    
END MAIN