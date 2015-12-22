SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_transform_matrix_sp.sql
Type:			Stored Procedure
Called From:	Matrix
Description:	Transforms the current matrix output to the new tabular format
Developer:		Chris Tyler
Date:			18th May 2011

Revision History
v1.0	CT	18/05/11	Original version
v1.1	CT	08/10/12	On hand value changed to 2 decimal places
*/

CREATE PROC [dbo].[CVO_Transform_Matrix_sp]
AS
BEGIN
	declare @loop int,
			@sql varchar(500),
			@size_des varchar(4),
			@eye_size DECIMAL(20, 8),
			@overflow int,
			@continued varchar(11)
	

	CREATE TABLE #Transform (
		color		VARCHAR(266), 
		s1_size		INT,
		s1_part_no  VARCHAR(50),
		s1_qty		INT, 
		s1_weeks	DECIMAL(20,2), --INT, -- v1.1
		s1_display	smallint default 0,
		s2_size		INT,
		s2_part_no  VARCHAR(50),
		s2_qty		INT, 
		s2_weeks	DECIMAL(20,2), --INT, -- v1.1
		s2_display	smallint default 0,
		s3_size		INT,
		s3_part_no  VARCHAR(50),
		s3_qty		INT, 
		s3_weeks	DECIMAL(20,2), --INT, -- v1.1
		s3_display	smallint default 0,
		s4_size		INT,
		s4_part_no  VARCHAR(50),
		s4_qty		INT, 
		s4_weeks	DECIMAL(20,2), --INT, -- v1.1
		s4_display	smallint default 0,
		s5_size		INT,
		s5_part_no  VARCHAR(50),
		s5_qty		INT, 
		s5_weeks	DECIMAL(20,2), --INT, -- v1.1
		s5_display	smallint default 0,
		s6_size		INT,
		s6_part_no  VARCHAR(50),
		s6_qty		INT, 
		s6_weeks	DECIMAL(20,2), --INT, -- v1.1
		s6_display	smallint default 0,
		s7_size		INT,
		s7_part_no  VARCHAR(50),
		s7_qty		INT, 
		s7_weeks	DECIMAL(20,2), --INT, -- v1.1
		s7_display	smallint default 0,
		s8_size		INT,
		s8_part_no  VARCHAR(50),
		s8_qty		INT, 
		s8_weeks	DECIMAL(20,2), --INT, -- v1.1
		s8_display	smallint default 0,
		s9_size		INT,
		s9_part_no  VARCHAR(50),
		s9_qty		INT, 
		s9_weeks	DECIMAL(20,2), --INT, -- v1.1
		s9_display	smallint default 0,
		s10_size	INT,
		s10_part_no  VARCHAR(50),
		s10_qty		INT, 
		s10_weeks	DECIMAL(20,2), --INT, -- v1.1
		s10_display	smallint default 0)


	-- set up the color lines
	INSERT INTO #transform (color) SELECT DISTINCT color from #temp order by color

	-- Loop through sizes and populate the table
	SET @loop = 0
	SET @eye_size = 0
	SET @overflow = 0
	SET @continued = ''
	WHILE 1 = 1
	BEGIN
		
		SET @loop = @loop + 1

		-- get next size
		SELECT TOP 1 
			@eye_size = eye_size
		FROM
			#temp
		WHERE
			eye_size > @eye_size
		ORDER BY
			eye_size

		IF @@ROWCOUNT = 0 
			Break
		
		-- Maximum of 10 sizes per line, if we have more than 10 sizes than create extra rows
		IF  @loop > 10
		BEGIN
			SET @loop = 1
			SET @overflow = @overflow + 1
			SET @continued = ' (cont. ' + LTRIM(RTRIM(CAST(@overflow as varchar(2)))) + ')'
			INSERT INTO #transform (color) SELECT DISTINCT SUBSTRING((color + @continued),1,266) FROM #temp WHERE eye_size >= @eye_size order by SUBSTRING((color + @continued),1,266)
		END 

		SET @size_des = 's' + CAST(@loop AS VARCHAR(2)) + '_'
		-- START v1.1
		--SET @sql = 'UPDATE a SET ' + @size_des + 'size = CAST(b.eye_size AS INT), ' + @size_des + 'part_no = b.part_no, ' + @size_des + 'weeks = CAST(b.weeks AS INT), ' + @size_des + 'qty = CAST(b.quantity AS INT), ' + @size_des + 'display = 1'
		SET @sql = 'UPDATE a SET ' + @size_des + 'size = CAST(b.eye_size AS INT), ' + @size_des + 'part_no = b.part_no, ' + @size_des + 'weeks = ROUND(b.weeks,2), ' + @size_des + 'qty = CAST(b.quantity AS INT), ' + @size_des + 'display = 1'
		-- END v1.1
		SET @sql = @sql + ' FROM #Transform a INNER JOIN #temp b ON a.color = SUBSTRING((b.color + ' + '''' +  + @continued + + '''' + '),1,266) WHERE b.eye_size = ' + CAST(@eye_size AS VARCHAR(50))
		PRINT @sql
		EXEC (@sql)
	END

	SELECT  
		*
	FROM 
		#transform 
	ORDER BY 
		color
	drop table #transform
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Transform_Matrix_sp] TO [public]
GO
