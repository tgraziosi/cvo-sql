SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_update_template_information_sp]
AS
--THIS STORED PROCEDURE WILL UPDATE THE TEMP TABLES STORING THE "TEMPLATE" INFORMATION THAT
--WAS USED TO CREATE THIS QUOTATION
DECLARE
	@template_name	   	varchar(30),
	@location	   	varchar(10),
	@tran_id		int,
	@category	   	varchar(50),
	@change_description 	varchar(40),
	@new_value		decimal(20,8),
	@fee			decimal(20,8),
	@transaction		varchar(100),
	@expert			char(1)

	--UPDATE TEMPLATE VALUE
	DECLARE template_update CURSOR FOR
		SELECT template_name, location, new_value 
    		  FROM #template_value_change
	OPEN template_update
	FETCH NEXT FROM template_update INTO @template_name, @location, @new_value
	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE #quote_templates_used_tbl
			SET value = @new_value
		WHERE template_name = @template_name
		  AND location = @location

		FETCH NEXT FROM template_update INTO @template_name, @location, @new_value
	END
	CLOSE template_update
	DEALLOCATE template_update
	
	--UPDATE TEMPLATE LABOR
	DECLARE template_labor_update CURSOR FOR
		SELECT template_name, location, tran_id, category, change_description, new_fee
    		  FROM #template_labor_change
	OPEN template_labor_update
	FETCH NEXT FROM template_labor_update INTO @template_name, @location, @tran_id, @category, @change_description, @fee
	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @change_description = 'Fee Changed'
		BEGIN
			UPDATE #quote_templates_labor_details_tbl
				SET fee = @fee
			WHERE template_name = @template_name
			  AND location = @location
			  AND tran_id = @tran_id
			  AND category = @category
		END 
		ELSE IF @change_description = 'New Transaction'
		BEGIN
			INSERT INTO #quote_templates_labor_details_tbl (template_name, location, tran_id, category, fee)
				SELECT @template_name, @location, @tran_id, @category, @fee
				
			SELECT @transaction = [transaction], @expert = expert
			  FROM tdc_3pl_labor_avail_transactions (NOLOCK)
			WHERE tran_id = @tran_id
			  AND category = @category

			INSERT INTO #quote_assigned_labor_values (category, tran_id, qty, [transaction], expert)
				SELECT @category, @tran_id, 0, @transaction, @expert

		END
		ELSE IF @change_description = 'Removed Transaction'
		BEGIN
			DELETE FROM #quote_templates_labor_details_tbl 
				WHERE template_name = @template_name
				  AND location = @location
				  AND tran_id = @tran_id
				  AND category = @category

			--REMOVE THOSE NOT BEING USED ANYMORE
			DELETE FROM #quote_assigned_labor_values
				WHERE category = @category
				  AND tran_id  = @tran_id
		END

		FETCH NEXT FROM template_labor_update INTO @template_name, @location, @tran_id, @category, @change_description, @fee
	END
	CLOSE template_labor_update
	DEALLOCATE template_labor_update	

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_update_template_information_sp] TO [public]
GO
