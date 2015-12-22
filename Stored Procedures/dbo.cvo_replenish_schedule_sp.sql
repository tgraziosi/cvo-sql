SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_replenish_schedule_sp] 
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@replen_id		int,
			@last_replen_id	int,
			@ret			int,
			@location		varchar(10),
			@replen_group	varchar(20),
			@fill_opt		char(1),
			@station_id		varchar(50),
			@userid			varchar(50)

	-- Create working tables
	IF (OBJECT_ID('tempdb..#cvo_replen_label') IS NOT NULL) 
		DROP TABLE #cvo_replen_label 
	IF (OBJECT_ID('tempdb..#PrintData_Output') IS NOT NULL) 
		DROP TABLE #PrintData_Output 
	IF (OBJECT_ID('tempdb..#Select_Result') IS NOT NULL) 
		DROP TABLE #Select_Result 
	IF (OBJECT_ID('tempdb..#cvo_replenishment') IS NOT NULL) 
		DROP TABLE #cvo_replenishment 

	CREATE TABLE #cvo_replen_label( 
		row_id		int identity (1,1) NOT NULL, 
		print_value varchar(300) NOT NULL)  

	CREATE TABLE #PrintData_Output(
		format_id			varchar(40) NOT NULL, 
		printer_id			varchar(30) NOT NULL, 
		number_of_copies	int NOT NULL)  
	
	CREATE TABLE #Select_Result(
		data_field		varchar(300) NOT NULL, 
		data_value		varchar(300) NULL) 

	CREATE TABLE #cvo_replenishment(  
		row_id			int identity(1,1),                                   
		replen_group    int,                                   
		location        varchar(10),                                   
		queue_id        int,                                   
		part_no         varchar(30),                                   
		part_desc       varchar(255),                                   
		from_bin        varchar(20),                                   
		to_bin          varchar(20),                                   
		qty             decimal(20,8)) 

	IF (OBJECT_ID('tempdb..#temp_bin_list') IS NOT NULL) 
		DROP TABLE #temp_bin_list  
	IF (OBJECT_ID('tempdb..#temp_lb_stock') IS NOT NULL) 
		DROP TABLE #temp_lb_stock  
	IF (OBJECT_ID('tempdb..#rep_bin_move_detail') IS NOT NULL) 
		DROP TABLE #rep_bin_move_detail  
	IF (OBJECT_ID('tempdb..#temp_repl_bins') IS NOT NULL) 
		DROP TABLE #temp_repl_bins  
	IF (OBJECT_ID('tempdb..#temp_repl_display') IS NOT NULL) 
		DROP TABLE #temp_repl_display  

	CREATE TABLE #temp_lb_stock ( 
		location		VARCHAR(10) NOT NULL, 
		part_no			VARCHAR(30) NOT NULL, 
		lot_ser			VARCHAR(25) NOT NULL, 
		bin_no			VARCHAR(12) NOT NULL, 
		qty				DECIMAL(20,8) NOT NULL)  

	CREATE TABLE #rep_bin_move_detail (
		part_no			VARCHAR(30) NOT NULL, 
		lot_ser			VARCHAR(25) NOT NULL, 
		bin_no			VARCHAR(12) NOT NULL, 
		to_bin			VARCHAR(12) NOT NULL, 
		qty				DECIMAL(20, 8) NOT NULL,  
		isforced		int NOT NULL,
		replen_id		int NOT NULL) 

	CREATE TABLE #temp_bin_list ( 
		replen_id		INT,     
		bin_no			VARCHAR(12) NOT NULL,  
		part_no			VARCHAR(30) NOT NULL,  
		priority		int NOT NULL) 

	CREATE TABLE #temp_repl_bins ( 
		replen_id		INT, 
		location		VARCHAR(10) NOT NULL,  
		bin_no			VARCHAR(12) NOT NULL,  
		part_no			VARCHAR(30) NOT NULL,  
		repl_max_lvl	DECIMAL(20,8) NOT NULL,  
		repl_min_lvl	DECIMAL(20,8) NOT NULL, 
		repl_qty		DECIMAL(20, 8) NOT NULL, 
		priority		INT NOT NULL) 

	CREATE TABLE #temp_repl_display ( 
		replen_id		INT, 
		replen_group	VARCHAR(20), 
		group_code		VARCHAR(25),   
		bin_no			VARCHAR (12) NOT NULL,   
		part_no			VARCHAR(30) NOT NULL,   
		replenish_min_lvl VARCHAR(28) NULL,   
		replenish_max_lvl VARCHAR(28) NULL,  
		replenish_qty	VARCHAR(28) NULL,   
		qty				DECIMAL(20,8), 
		available_qty	DECIMAL(20,8), 
		inqueue			DECIMAL(20,8) default 0, 
		inqueue_b2b		DECIMAL(20,8) default 0 , 
		location		VARCHAR (25) NOT NULL,  
		isforced		int NULL,  
		selected		INT NULL ) 

	-- Check if there is a replenishment scheduled
	IF EXISTS (SELECT 1 FROM cvo_replenish_schedule (NOLOCK) WHERE schedule_date < GETDATE())
	BEGIN
		CREATE TABLE #replen (
			replen_id	int,
			bin_no		varchar(12) NOT NULL,
			part_no		varchar(30) NOT NULL,
			fill_opt	int NOT NULL,
			priority	int NOT NULL,
			station_id	varchar(50),
			userid		varchar(50))

		INSERT	#replen (replen_id, bin_no, part_no, fill_opt, priority, station_id, userid)
		SELECT	replen_id, bin_no, part_no, fill_opt, priority, station_id, userid
		FROM	cvo_replenish_schedule (NOLOCK) 
		WHERE	schedule_date < GETDATE()

		SET @last_replen_id = 0

		SELECT	TOP 1 @replen_id = replen_id,
				@fill_opt = CASE WHEN fill_opt = 1 THEN 'Y' ELSE 'N' END,
				@station_id = station_id,
				@userid = userid
		FROM	#replen
		WHERE	replen_id > @last_replen_id
		ORDER BY replen_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			-- Clear working table
			DELETE #cvo_replen_label 
			DELETE #PrintData_Output 
			DELETE #Select_Result 
			DELETE #cvo_replenishment 
			DELETE #temp_bin_list  
			DELETE #temp_lb_stock  
			DELETE #rep_bin_move_detail  
			DELETE #temp_repl_bins  
			DELETE #temp_repl_display  

			-- Insert records for the replenishment routine
			INSERT	#temp_bin_list (replen_id, bin_no, part_no, priority )	
			SELECT	replen_id, bin_no, part_no, priority
			FROM	cvo_replenish_schedule (NOLOCK)
			WHERE	replen_id = @replen_id					

			SELECT	@replen_group = replen_group,
					@location = location
			FROM	replenishment_groups (NOLOCK)				
			WHERE	replen_id = @replen_id	

			-- Call WMS adhoc replenishment
			EXEC @ret = tdc_adhoc_bin_replenish_sp @location, @replen_group, 'ALL', @fill_opt, 1
 			
			IF (@@ERROR) = 0
			BEGIN
				DELETE cvo_replenish_schedule WHERE replen_id = @replen_id
			END

			-- Print the labels
			EXEC dbo.cvo_replenish_print_sp @station_id, @userid, 0
			EXEC dbo.cvo_replenish_print_sp @station_id, @userid, 1

			SET @last_replen_id = @replen_id

			SELECT	TOP 1 @replen_id = replen_id,
					@fill_opt = CASE WHEN fill_opt = 1 THEN 'Y' ELSE 'N' END,
					@station_id = station_id,
					@userid = userid
			FROM	#replen
			WHERE	replen_id > @last_replen_id
			ORDER BY replen_id ASC
		END

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_replenish_schedule_sp] TO [public]
GO
