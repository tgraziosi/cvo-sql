SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_graphical_bin_view_add_row_columns_sp]
	@template_id			int,	  --TEMPLATE ID WE ARE WORKING WITH IN VB
	@userid				varchar(50),
	@template_add_type		char(1),  --VALID VALUES: C - FOR ADDING COLUMN(S) AND R - FOR ADDING ROW(S)
	@template_option		int,  	  --VALID VALUES: 0 - ADD AT THE END, 1 - ADD BEFORE ROW/COLUMN(@template_addlocation_option), 2 - ADD AFTER ROW/COLUMN(@template_addlocation_option)
	@template_addlocation_option	int,	  --VALID VALUES: THE VALUE HERE IS THE ROW/COLUMN POSITION THAT WE NEED TO ADD ONTO EITHER BEFORE OR AFTER, DEPENDING ON ABOVE PARAMETER (*NOTE* - THIS VALUE IS ONLY IMPORTANT IF @template_option <> 0)
	@template_add_qty		int,	  --VALID VALUES: ANYTHING POSITIVE - THIS IS THE NUMBER OF ROWS/COLUMNS WE NEED TO ADD
	@err_msg			varchar(255)	OUTPUT

AS
DECLARE @row_count	int,
	@col_count	int,
	@current_row	int,
	@current_col	int,
	@last_row	int,  --CALCULATED VARIABLES USED TO TELL US WHAT OUR LAST ROW IS
	@last_col	int,  --CALCULATED VARIABLES USED TO TELL US WHAT OUR LAST COL IS
	@language 	varchar(10)

SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @userid


IF @template_add_type NOT IN ('C', 'R') 
BEGIN
	--'Invalid Add Type specified.'
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 8 AND language = @language
	RETURN -1
END

SELECT 	@row_count = ISNULL(MAX(row),0), @col_count = ISNULL(MAX(col),0) 
	FROM #tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id
--USE TABLE #tdc_graphical_bin_store
IF @template_add_type = 'C'	--ADDING COLUMN(S)
BEGIN	
	IF @template_option = 0 	--ADD COLUMNS TO THE END OF THE CURRENT TABLE
	BEGIN
		IF @row_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A COLUMN RECORD TO THE FIRST ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @current_col = @col_count + 1 --GET THE NEXT COLUMN TO START ADDING DATA
			SELECT @last_col = @current_col + @template_add_qty
			WHILE @current_col < @last_col
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_col = @current_col + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A COLUMN RECORD FOR EACH ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @last_row = @row_count

			WHILE @current_row <= @last_row
			BEGIN
				SELECT @current_col = @col_count + 1 --GET THE NEXT COLUMN TO START ADDING DATA
				SELECT @last_col = @current_col + @template_add_qty
				WHILE @current_col < @last_col
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_col = @current_col + 1
				END
				SELECT @current_row = @current_row + 1
			END
		END
	END
	ELSE IF @template_option = 1    --ADD COLUMNS TO THE CURRENT TABLE BEFORE THE SPECIFIED COLUMN
	BEGIN
		--IF THE COLUMN THE USER TELLS US TO INSERT BEFORE DOES NOT EXIST, WE GIVE THEM AN ERROR
		IF NOT EXISTS(select col from #tdc_graphical_bin_store (NOLOCK) WHERE col = @template_addlocation_option AND template_id = @template_id)
		BEGIN
			--'Specified insert column does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 4 AND language = @language
			RETURN -1
		END
		--UPDATE COLUMNS OF EXISTING RECORDS
		UPDATE #tdc_graphical_bin_store 
			SET col = col + @template_add_qty 
				WHERE col >= @template_addlocation_option AND template_id = @template_id

		IF @row_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A COLUMN RECORD TO THE FIRST ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @current_col = @template_addlocation_option --GET THE NEXT COLUMN TO START ADDING DATA
			SELECT @last_col = @current_col + @template_add_qty
			WHILE @current_col < @last_col
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_col = @current_col + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A COLUMN RECORD FOR EACH ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @last_row = @row_count

			WHILE @current_row <= @last_row
			BEGIN
				SELECT @current_col = @template_addlocation_option --GET THE NEXT COLUMN TO START ADDING DATA
				SELECT @last_col = @current_col + @template_add_qty
				WHILE @current_col < @last_col
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_col = @current_col + 1
				END
				SELECT @current_row = @current_row + 1
			END
		END

	END
	ELSE IF @template_option = 2    --ADD COLUMNS TO THE CURRENT TABLE AFTER THE SPECIFIED COLUMN
	BEGIN
		--IF THE COLUMN THE USER TELLS US TO INSERT AFTER DOES NOT EXIST, WE GIVE THEM AN ERROR
		IF NOT EXISTS(select col from #tdc_graphical_bin_store (NOLOCK) WHERE col = @template_addlocation_option AND template_id = @template_id)
		BEGIN
			--'Specified insert column does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 5 AND language = @language
			RETURN -1
		END
		--UPDATE COLUMNS OF EXISTING RECORDS
		UPDATE #tdc_graphical_bin_store 
			SET col = col + @template_add_qty 
				WHERE col > @template_addlocation_option AND template_id = @template_id

		IF @row_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A COLUMN RECORD TO THE FIRST ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @current_col = @template_addlocation_option + 1 --GET THE NEXT COLUMN TO START ADDING DATA
			SELECT @last_col = @current_col + @template_add_qty
			WHILE @current_col < @last_col
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_col = @current_col + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A COLUMN RECORD FOR EACH ROW IN THE TABLE
			SELECT @current_row = 1
			SELECT @last_row = @row_count

			WHILE @current_row <= @last_row
			BEGIN
				SELECT @current_col = @template_addlocation_option + 1 --GET THE NEXT COLUMN TO START ADDING DATA
				SELECT @last_col = @current_col + @template_add_qty
				WHILE @current_col < @last_col
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_col = @current_col + 1
				END
				SELECT @current_row = @current_row + 1
			END
		END
	END
END
ELSE --@template_add_type = 'R'			--ADDING ROW(S)
BEGIN
	IF @template_option = 0 	--ADD ROWS TO THE END OF THE CURRENT TABLE
	BEGIN
		IF @col_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A ROW RECORD TO THE FIRST COLUMN IN THE TABLE
			SELECT @current_row = @row_count + 1
			SELECT @current_col = 1
			SELECT @last_row = @current_row + @template_add_qty
			WHILE @current_row < @last_row
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_row = @current_row + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A ROW RECORD FOR EACH COLUMN IN THE TABLE
			SELECT @current_col = 1
			SELECT @last_col = @col_count

			WHILE @current_col <= @last_col
			BEGIN
				SELECT @current_row = @row_count + 1 --GET THE NEXT COLUMN TO START ADDING DATA
				SELECT @last_row = @current_row + @template_add_qty
				WHILE @current_row < @last_row
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_row = @current_row + 1
				END
				SELECT @current_col = @current_col + 1
			END
		END
	END
	ELSE IF @template_option = 1    --ADD ROWS TO THE CURRENT TABLE BEFORE THE SPECIFIED ROW
	BEGIN
		--IF THE ROW THE USER TELLS US TO INSERT BEFORE DOES NOT EXIST, WE GIVE THEM AN ERROR
		IF NOT EXISTS(select row from #tdc_graphical_bin_store (NOLOCK) WHERE row = @template_addlocation_option AND template_id = @template_id)
		BEGIN
			--'Specified insert row does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 6 AND language = @language
			RETURN -1
		END
		--UPDATE ROWS OF EXISTING RECORDS
		UPDATE #tdc_graphical_bin_store 
			SET row = row + @template_add_qty 
				WHERE row >= @template_addlocation_option AND template_id = @template_id

		IF @col_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A ROW RECORD TO THE FIRST COLUMN IN THE DATABASE
			SELECT @current_col = 1
			SELECT @current_row = @template_addlocation_option --GET THE NEXT ROW TO START ADDING DATA
			SELECT @last_row = @current_row + @template_add_qty
			WHILE @current_row < @last_row
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_row = @current_row + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A ROW RECORD FOR EACH COLUMN IN THE DATABASE
			SELECT @current_col = 1
			SELECT @last_col = @col_count

			WHILE @current_col <= @last_col
			BEGIN
				SELECT @current_row = @template_addlocation_option --GET THE NEXT COLUMN TO START ADDING DATA
				SELECT @last_row = @current_row + @template_add_qty
				WHILE @current_row < @last_row
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_row = @current_row + 1
				END
				SELECT @current_col = @current_col + 1
			END
		END

	END
	ELSE IF @template_option = 2    --ADD ROWS TO THE CURRENT TABLE AFTER THE SPECIFIED ROW
	BEGIN
		--IF THE ROW THE USER TELLS US TO INSERT AFTER DOES NOT EXIST, WE GIVE THEM AN ERROR
		IF NOT EXISTS(select row from #tdc_graphical_bin_store (NOLOCK) WHERE row = @template_addlocation_option AND template_id = @template_id)
		BEGIN
			--'Specified insert row does not exist.'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 7 AND language = @language
			RETURN -1
		END
		--UPDATE ROWS OF EXISTING RECORDS
		UPDATE #tdc_graphical_bin_store 
			SET row = row + @template_add_qty 
				WHERE row > @template_addlocation_option AND template_id = @template_id

		IF @col_count IN (0, 1)
		BEGIN   --WE NEED TO ADD A ROW RECORD TO THE FIRST COLUMN IN THE DATABASE
			SELECT @current_col = 1
			SELECT @current_row = @template_addlocation_option + 1 --GET THE NEXT ROW TO START ADDING DATA
			SELECT @last_row = @current_row + @template_add_qty
			WHILE @current_row < @last_row
			BEGIN
				INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
					VALUES(@template_id, @current_row, @current_col, NULL)
				SELECT @current_row = @current_row + 1
			END
		END
		ELSE
		BEGIN   --WE NEED TO ADD A ROW RECORD FOR EACH COLUMN IN THE DATABASE
			SELECT @current_col = 1
			SELECT @last_col = @col_count

			WHILE @current_col <= @last_col
			BEGIN
				SELECT @current_row = @template_addlocation_option + 1 --GET THE NEXT ROW TO START ADDING DATA
				SELECT @last_row = @current_row + @template_add_qty
				WHILE @current_row < @last_row
				BEGIN
					INSERT INTO #tdc_graphical_bin_store (template_id, row, col, bin_no) 
						VALUES(@template_id, @current_row, @current_col, NULL)
					SELECT @current_row = @current_row + 1
				END
				SELECT @current_col = @current_col + 1
			END
		END
	END
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_graphical_bin_view_add_row_columns_sp] TO [public]
GO
