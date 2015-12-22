SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 23/04/2015 - Performance Changes
  
CREATE PROCEDURE [dbo].[tdc_print_label_sp] (@module       varchar(3),   
										@trans        varchar(20),   
										@trans_source varchar(2),  
										@station_id   varchar(20))  
AS  
BEGIN
  
	DECLARE @input_prompt_count    int,          @printed_prompt_count  int,            
			@number_of_copies      int,      @not_found             int,  
			@label_printed         int,          @printer_id            varchar(30),  
			@format_id             varchar(40),    
			@label_path            varchar(100), @watchdog_path         varchar(100),  
			@input_prompt_select_0 varchar(50),  @input_prompt_select_1 varchar(50),    
			@input_prompt_select_2 varchar(50),  @input_prompt_select_3 varchar(50),   
			@input_prompt_select_4 varchar(50),  @input_prompt_select_5 varchar(50),   
			@input_prompt_select_6 varchar(50),  @input_prompt_select_7 varchar(50),    
			@input_prompt_select_8 varchar(50),  @input_prompt_select_9 varchar(50),   
			@input_prompt_result_0 varchar(80),  @input_prompt_result_1 varchar(80),   
			@input_prompt_result_2 varchar(80),  @input_prompt_result_3 varchar(80),   
			@input_prompt_result_4 varchar(80),  @input_prompt_result_5 varchar(80),   
			@input_prompt_result_6 varchar(80),  @input_prompt_result_7 varchar(80),    
			@input_prompt_result_8 varchar(80),  @input_prompt_result_9 varchar(80),  
			@select_result_name    varchar(50),  @select_result_value   varchar(80),  
			@input_value_name      varchar(50),  @input_value_value     varchar(80)  
  
	DECLARE @print_id             varchar(100),  
			@normal_label_printed int  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int,
			@row2_id		int,
			@last_row2_id	int
	-- v1.0 End
  
	--Initialize variables  
	SELECT @label_printed = 0, @printed_prompt_count = 0, @number_of_copies = 0, @normal_label_printed = 0  
  
	IF LEN(@station_id) = 0  
	BEGIN  
		RAISERROR ('User_ID / Station_ID cannot be NULL', 16, 1)  
		RETURN -1  
	END  
  
	-- v1.0 Start
	CREATE TABLE #Input_Prompt_Cursor (
		row_id					int IDENTITY(1,1),
		format_id				varchar(40) NULL, 
		input_prompt_count		int NULL,   
		input_prompt_select_0	varchar(50) NULL, 
		input_prompt_select_1	varchar(50) NULL, 
		input_prompt_select_2	varchar(50) NULL, 
		input_prompt_select_3	varchar(50) NULL,	   
		input_prompt_select_4	varchar(50) NULL, 
		input_prompt_select_5	varchar(50) NULL, 
		input_prompt_select_6	varchar(50) NULL, 
		input_prompt_select_7	varchar(50) NULL,   
		input_prompt_select_8	varchar(50) NULL, 
		input_prompt_select_9	varchar(50) NULL, 
		input_prompt_result_0	varchar(80) NULL, 
		input_prompt_result_1	varchar(80) NULL,  
		input_prompt_result_2	varchar(80) NULL, 
		input_prompt_result_3	varchar(80) NULL, 
		input_prompt_result_4	varchar(80) NULL, 
		input_prompt_result_5	varchar(80) NULL,   
		input_prompt_result_6	varchar(80) NULL, 
		input_prompt_result_7	varchar(80) NULL, 
		input_prompt_result_8	varchar(80) NULL, 
		input_prompt_result_9	varchar(80) NULL)

	CREATE TABLE #Select_Result_Cursor (
		row2_id			int IDENTITY(1,1),
		data_field		varchar(50) NULL,
		data_value		varchar(80) NULL)

	INSERT	#Input_Prompt_Cursor (format_id, input_prompt_count, input_prompt_select_0, input_prompt_select_1, input_prompt_select_2, input_prompt_select_3,   
				input_prompt_select_4, input_prompt_select_5, input_prompt_select_6, input_prompt_select_7, input_prompt_select_8, input_prompt_select_9, 
				input_prompt_result_0, input_prompt_result_1, input_prompt_result_2, input_prompt_result_3, input_prompt_result_4, input_prompt_result_5,   
				input_prompt_result_6, input_prompt_result_7, input_prompt_result_8, input_prompt_result_9)
	-- v1.0 DECLARE Input_Prompt_Cursor CURSOR FOR  
	SELECT	format_id, input_prompt_count,   
			input_prompt_select_0, input_prompt_select_1, input_prompt_select_2, input_prompt_select_3,   
			input_prompt_select_4, input_prompt_select_5, input_prompt_select_6, input_prompt_select_7,   
			input_prompt_select_8, input_prompt_select_9, input_prompt_result_0, input_prompt_result_1,  
			input_prompt_result_2, input_prompt_result_3, input_prompt_result_4, input_prompt_result_5,   
			input_prompt_result_6, input_prompt_result_7, input_prompt_result_8, input_prompt_result_9  
	FROM	tdc_label_format_control (NOLOCK)   
	WHERE	module       = @module  
    AND		trans        = @trans   
    AND		trans_source = @trans_source  
	ORDER BY input_prompt_count DESC  
  
	-- v1.0 
	/*
	OPEN Input_Prompt_Cursor  
	FETCH NEXT FROM Input_Prompt_Cursor   
    INTO @format_id, @input_prompt_count,    
    @input_prompt_select_0, @input_prompt_select_1, @input_prompt_select_2, @input_prompt_select_3, @input_prompt_select_4,   
    @input_prompt_select_5, @input_prompt_select_6, @input_prompt_select_7, @input_prompt_select_8, @input_prompt_select_9,  
    @input_prompt_result_0, @input_prompt_result_1, @input_prompt_result_2, @input_prompt_result_3, @input_prompt_result_4,  
    @input_prompt_result_5, @input_prompt_result_6, @input_prompt_result_7, @input_prompt_result_8, @input_prompt_result_9  
	
	WHILE (@@FETCH_STATUS = 0)  
	*/

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@format_id = format_id, 
			@input_prompt_count = input_prompt_count,   
			@input_prompt_select_0 = input_prompt_select_0, 
			@input_prompt_select_1 = input_prompt_select_1, 
			@input_prompt_select_2 = input_prompt_select_2, 
			@input_prompt_select_3 = input_prompt_select_3,   
			@input_prompt_select_4 = input_prompt_select_4, 
			@input_prompt_select_5 = input_prompt_select_5, 
			@input_prompt_select_6 = input_prompt_select_6, 
			@input_prompt_select_7 = input_prompt_select_7,   
			@input_prompt_select_8 = input_prompt_select_8, 
			@input_prompt_select_9 = input_prompt_select_9, 
			@input_prompt_result_0 = input_prompt_result_0, 
			@input_prompt_result_1 = input_prompt_result_1,  
			@input_prompt_result_2 = input_prompt_result_2, 
			@input_prompt_result_3 = input_prompt_result_3, 
			@input_prompt_result_4 = input_prompt_result_4, 
			@input_prompt_result_5 = input_prompt_result_5,   
			@input_prompt_result_6 = input_prompt_result_6, 
			@input_prompt_result_7 = input_prompt_result_7, 
			@input_prompt_result_8 = input_prompt_result_8, 
			@input_prompt_result_9 = input_prompt_result_9
	FROM	#Input_Prompt_Cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN  
		IF (@label_printed > 0) AND (@input_prompt_count <> @printed_prompt_count)  
		-- If we reach this code we have printed at least one label and have  
		-- cycled through the rest of the entries in tdc_label_format_control  
		-- for that input prompt count and printed those labels as well. We   
		-- are finished with PrintLabel.  
			BREAK  
  
		IF @input_prompt_count = 0  
		BEGIN  
			----- Processing --------------------------------------------------------      
			IF EXISTS ( SELECT * FROM tdc_tx_print_routing (NOLOCK) WHERE module = @module AND trans = @trans   
					AND trans_source = @trans_source AND format_id = @format_id AND user_station_id = @station_id)        
			BEGIN  
				--Get Printer_Id and Number of copies  
				SELECT @printer_id = '', @number_of_copies = 0  
  
				SELECT	@printer_id       = printer,  
						@number_of_copies = quantity  
				FROM	tdc_tx_print_routing (NOLOCK)   
				WHERE	module          = @module   
				AND		trans           = @trans   
				AND		trans_source    = @trans_source   
				AND		format_id       = @format_id   
				AND		user_station_id = @station_id  
  
				INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)   
                VALUES (@format_id, @printer_id, @number_of_copies)  
     
				SELECT @normal_label_printed = 1  
				SELECT @label_printed = 1  
			END  
			ELSE  
			BEGIN  
				-- IF we did not print a valid label, print a default label  
				IF @normal_label_printed = 0  
				BEGIN  
					IF EXISTS (SELECT * FROM tdc_tx_print_routing (NOLOCK) WHERE module = @module AND trans = @trans   
							AND trans_source = @trans_source AND format_id = @format_id AND len(user_station_id) <= 0)  
					BEGIN  
						--Get Default Printer_Id and Number of copies for the format_id  
						SELECT @printer_id = '', @number_of_copies = 0  
   
						SELECT	@printer_id       = printer,  
								@number_of_copies = quantity   
						FROM	tdc_tx_print_routing (NOLOCK)  
						WHERE	module          = @module   
						AND		trans           = @trans   
						AND		trans_source    = @trans_source   
						AND		format_id       = @format_id   
						AND		LEN(user_station_id) <= 0  
   
						INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)   
                        VALUES (@format_id, @printer_id, @number_of_copies)  
   
						SELECT @label_printed = 1  
					END  
				END  
			END  
		END   
		--------------------------------------------------------------------------------------------------------------------------------------  
		ELSE  
		BEGIN  
			TRUNCATE TABLE #Select_Result  
			SELECT @select_result_name = NULL, @select_result_value = NULL  
  
			IF @input_prompt_count >= 1 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_0, @input_prompt_result_0)  
			IF @input_prompt_count >= 2 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_1, @input_prompt_result_1)  
			IF @input_prompt_count >= 3 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_2, @input_prompt_result_2)  
			IF @input_prompt_count >= 4 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_3, @input_prompt_result_3)  
			IF @input_prompt_count >= 5 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_4, @input_prompt_result_4)  
			IF @input_prompt_count >= 6 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_5, @input_prompt_result_5)  
			IF @input_prompt_count >= 7 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_6, @input_prompt_result_6)  
			IF @input_prompt_count >= 8 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_7, @input_prompt_result_7)  
			IF @input_prompt_count >= 9 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_8, @input_prompt_result_8)  
			IF @input_prompt_count = 10 INSERT INTO #Select_Result (data_field, data_value) VALUES (@input_prompt_select_9, @input_prompt_result_9)  
			IF @input_prompt_count > 10 BREAK  -- Maximum input_prompt_count is 10  
  
			TRUNCATE TABLE #Select_Result_Cursor

			INSERT	#Select_Result_Cursor (data_field, data_value)
			-- v1.0 DECLARE Select_Result_Cursor CURSOR FOR  
			SELECT	data_field, data_value FROM  #Select_Result  
  
			-- v1.0 OPEN Select_Result_Cursor  
			-- v1.0 FETCH NEXT FROM Select_Result_Cursor INTO @select_result_name, @select_result_value  
			-- v1.0 WHILE (@@FETCH_STATUS = 0)  

			SET @last_row2_id = 0

			SELECT	TOP 1 @row2_id = row2_id,
					@select_result_name = data_field,
					@select_result_value = data_value
			FROM	#Select_Result_Cursor
			WHERE	row2_id > @last_row2_id
			ORDER BY row2_id

			WHILE @@ROWCOUNT <> 0
			BEGIN   
				SELECT @not_found = 1  
   
				IF NOT EXISTS (SELECT * FROM #PrintData WHERE data_field = @select_result_name AND data_value = @select_result_value)  
					BREAK  
				ELSE  
					SELECT @not_found = 0  
  
				SET @last_row2_id = @row2_id

				SELECT	TOP 1 @row2_id = row2_id,
						@select_result_name = data_field,
						@select_result_value = data_value
				FROM	#Select_Result_Cursor
				WHERE	row2_id > @last_row2_id
				ORDER BY row2_id

				-- v1.0 FETCH NEXT FROM Select_Result_Cursor INTO @select_result_name, @select_result_value  
			END  
     
			-- v1.0 CLOSE      Select_Result_Cursor  
			-- v1.0 DEALLOCATE Select_Result_Cursor  
  
			IF @not_found = 0  
			BEGIN  
				--------- Processing ----------------------------------     
				IF EXISTS ( SELECT * FROM tdc_tx_print_routing (NOLOCK) WHERE module = @module AND trans = @trans   
						AND trans_source = @trans_source AND format_id = @format_id AND user_station_id   = @station_id)   
				BEGIN  
					--Get Printer_Id and Number of copies  
					SELECT @printer_id = '', @number_of_copies = 0  
   
					SELECT	@printer_id       = printer,  
							@number_of_copies = quantity   
					FROM	tdc_tx_print_routing (NOLOCK)   
					WHERE	module            = @module   
					AND		trans             = @trans   
					AND		trans_source      = @trans_source   
					AND		format_id         = @format_id   
					AND		user_station_id   = @station_id  
     
					INSERT INTO #PrintData_Output (format_id,  printer_id,  number_of_copies)   
                    VALUES (@format_id, @printer_id, @number_of_copies)  
  
					SELECT @normal_label_printed = 1  
					SELECT @label_printed = 1  
   
					-- We printed one label. Now we need to check if there is  
					-- any other labels defined with the same input_prompt_count  
				END  
				ELSE -- No Print Routing Settings. Try to get Defaults  
				BEGIN  
					IF @normal_label_printed = 0  
					BEGIN  
						IF EXISTS (SELECT * FROM tdc_tx_print_routing (NOLOCK) WHERE module = @module AND trans = @trans   
								AND trans_source = @trans_source AND format_id = @format_id AND len(user_station_id) <= 0)  
						BEGIN        
							--Get Default Printer_Id and Number of copies  
							SELECT @printer_id = '', @number_of_copies = 0  
    
							SELECT	@printer_id       = printer,   
									@number_of_copies = quantity  
							FROM	tdc_tx_print_routing (NOLOCK)   
							WHERE	module            = @module   
							AND		trans             = @trans   
							AND		trans_source      = @trans_source   
							AND		format_id         = @format_id   
							AND		LEN(user_station_id) <= 0  
        
							INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)   
                            VALUES (@format_id, @printer_id, @number_of_copies)  
      
							SELECT @label_printed = 1  
						END  
					END  
				END  
			END  
		END  
		-------------------------------------------------------------------------------------------------------------------------  
  
		IF @label_printed > 0  
			SELECT @printed_prompt_count = @input_prompt_count  

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@format_id = format_id, 
				@input_prompt_count = input_prompt_count,   
				@input_prompt_select_0 = input_prompt_select_0, 
				@input_prompt_select_1 = input_prompt_select_1, 
				@input_prompt_select_2 = input_prompt_select_2, 
				@input_prompt_select_3 = input_prompt_select_3,   
				@input_prompt_select_4 = input_prompt_select_4, 
				@input_prompt_select_5 = input_prompt_select_5, 
				@input_prompt_select_6 = input_prompt_select_6, 
				@input_prompt_select_7 = input_prompt_select_7,   
				@input_prompt_select_8 = input_prompt_select_8, 
				@input_prompt_select_9 = input_prompt_select_9, 
				@input_prompt_result_0 = input_prompt_result_0, 
				@input_prompt_result_1 = input_prompt_result_1,  
				@input_prompt_result_2 = input_prompt_result_2, 
				@input_prompt_result_3 = input_prompt_result_3, 
				@input_prompt_result_4 = input_prompt_result_4, 
				@input_prompt_result_5 = input_prompt_result_5,   
				@input_prompt_result_6 = input_prompt_result_6, 
				@input_prompt_result_7 = input_prompt_result_7, 
				@input_prompt_result_8 = input_prompt_result_8, 
				@input_prompt_result_9 = input_prompt_result_9
		FROM	#Input_Prompt_Cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
 
		-- v1.0 
		/*
		FETCH NEXT FROM Input_Prompt_Cursor INTO @format_id, @input_prompt_count,    
		@input_prompt_select_0, @input_prompt_select_1, @input_prompt_select_2, @input_prompt_select_3, @input_prompt_select_4,   
		@input_prompt_select_5, @input_prompt_select_6, @input_prompt_select_7, @input_prompt_select_8, @input_prompt_select_9,  
		@input_prompt_result_0, @input_prompt_result_1, @input_prompt_result_2, @input_prompt_result_3, @input_prompt_result_4,  
		@input_prompt_result_5, @input_prompt_result_6, @input_prompt_result_7, @input_prompt_result_8, @input_prompt_result_9  
		*/
	END  
  
	-- v1.0 CLOSE      Input_Prompt_Cursor  
	-- v1.0 DEALLOCATE Input_Prompt_Cursor  
  
	IF @label_printed > 0  
		RETURN 0  
	ELSE  
		RETURN -1  

END
GO
GRANT EXECUTE ON  [dbo].[tdc_print_label_sp] TO [public]
GO
