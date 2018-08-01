SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_auto_replenish_sp] @replen_group VARCHAR(20) = NULL, @fill_to_max_ind CHAR(1) = null

AS

BEGIN

-- exec cvo_auto_replenish_sp 'HB --> FP (Frames)'

-- exec cvo_auto_replenish_sp 'HB --> FP (Suns)'

SET NOCOUNT ON 
SET ANSI_WARNINGS OFF

DECLARE
        @location   varchar(10),  
        @perc_to_min  int,  
        @instock_option  int,  
        @instock_qty  decimal(20,8),  
        @available_option int,  
        @available_qty  decimal(20,8),  
        @part_type   varchar(20),  
        @pom_from   datetime,  
        @pom_to    datetime,  
        @results_returned int,  
        -- @fill_to_max_ind   char(1),  
        @review    int  ,
		@replen_id INT
           
IF @replen_group IS NULL SELECT @replen_group = 'HB --> FP (Frames)'
IF @fill_to_max_ind IS NULL SELECT @fill_to_max_ind = 'N'

IF ( OBJECT_ID('tempdb..#temp_bin_list') IS NOT NULL )
    DROP TABLE #temp_bin_list;  
IF ( OBJECT_ID('tempdb..#temp_lb_stock') IS NOT NULL )
    DROP TABLE #temp_lb_stock;  
IF ( OBJECT_ID('tempdb..#rep_bin_move_detail') IS NOT NULL )
    DROP TABLE #rep_bin_move_detail; 
IF ( OBJECT_ID('tempdb..#temp_repl_bins') IS NOT NULL )
    DROP TABLE #temp_repl_bins;  
IF ( OBJECT_ID('tempdb..#temp_repl_display') IS NOT NULL )
    DROP TABLE #temp_repl_display;  
CREATE TABLE #temp_lb_stock
    (
      location VARCHAR(10) NOT NULL ,
      part_no VARCHAR(30) NOT NULL ,
      lot_ser VARCHAR(25) NOT NULL ,
      bin_no VARCHAR(12) NOT NULL ,
      qty DECIMAL(20, 8) NOT NULL
    );  
CREATE TABLE #rep_bin_move_detail
    (
      part_no VARCHAR(30) NOT NULL ,
      lot_ser VARCHAR(25) NOT NULL ,
      bin_no VARCHAR(12) NOT NULL ,
      to_bin VARCHAR(12) NOT NULL ,
      qty DECIMAL(20, 8) NOT NULL ,
      isforced INT NOT NULL ,
      replen_id INT NOT NULL
    );
CREATE TABLE #temp_bin_list
    (
      replen_id INT ,
      bin_no VARCHAR(12) NOT NULL ,
      part_no VARCHAR(30) NOT NULL ,
      priority INT NOT NULL
    ); 
CREATE TABLE #temp_repl_bins
    (
      replen_id INT ,
      location VARCHAR(10) NOT NULL ,
      bin_no VARCHAR(12) NOT NULL ,
      part_no VARCHAR(30) NOT NULL ,
      repl_max_lvl DECIMAL(20, 8) NOT NULL ,
      repl_min_lvl DECIMAL(20, 8) NOT NULL ,
      repl_qty DECIMAL(20, 8) NOT NULL ,
      priority INT NOT NULL
    ); 
CREATE TABLE #temp_repl_display
    (
      replen_id INT ,
      replen_group VARCHAR(20) ,
      group_code VARCHAR(25) ,
      bin_no VARCHAR(12) NOT NULL ,
      part_no VARCHAR(30) NOT NULL ,
      replenish_min_lvl VARCHAR(28) NULL ,
      replenish_max_lvl VARCHAR(28) NULL ,
      replenish_qty VARCHAR(28) NULL ,
      qty DECIMAL(20, 8) ,
      available_qty DECIMAL(20, 8) ,
      inqueue DECIMAL(20, 8) DEFAULT 0 ,
      inqueue_b2b DECIMAL(20, 8) DEFAULT 0 ,
      location VARCHAR(25) NOT NULL ,
      isforced INT NULL ,
      selected INT NULL
    );


	 
SELECT @location = location,
	@perc_to_min = perc_to_min,
	@instock_option = in_stock_option,
	@instock_qty = in_stock_qty,
	@available_option = available_option,
	@part_type = part_type,
	@pom_from = '1/1/1900',
	@pom_to = '12/31/2999',
	@results_returned = -1,
	-- @filltype = 'Y',
	@review = 1,
	@replen_id = replen_id

FROM  replenishment_groups 
WHERE replen_group = @replen_group

IF EXISTS ( SELECT  1
            FROM    cvo_replenish_schedule
            WHERE   replen_id = @replen_id )
DELETE FROM dbo.cvo_replenish_schedule WHERE replen_id = @replen_id


EXEC dbo.cvo_replenish_retrieve_sp @replen_group, @location, @perc_to_min
	, @instock_option, @instock_qty
	, @available_option, @available_qty
	, @part_type, @pom_from, @pom_to
	, @results_returned, @fill_to_max_ind, @review


IF ( OBJECT_ID('tempdb..#cvo_replen_label') IS NOT NULL )
    DROP TABLE #cvo_replen_label; 
IF ( OBJECT_ID('tempdb..#PrintData_Output') IS NOT NULL )
    DROP TABLE #PrintData_Output; 
IF ( OBJECT_ID('tempdb..#Select_Result') IS NOT NULL )
    DROP TABLE #Select_Result; 
IF ( OBJECT_ID('tempdb..#cvo_replenishment') IS NOT NULL )
    DROP TABLE #cvo_replenishment; 

CREATE TABLE #cvo_replen_label
    (
      row_id INT IDENTITY(1, 1)
                 NOT NULL ,
      print_value VARCHAR(300) NOT NULL
    );
CREATE TABLE #PrintData_Output
    (
      format_id VARCHAR(40) NOT NULL ,
      printer_id VARCHAR(30) NOT NULL ,
      number_of_copies INT NOT NULL
    );
CREATE TABLE #Select_Result
    (
      data_field VARCHAR(300) NOT NULL ,
      data_value VARCHAR(300) NULL
    ); 
CREATE TABLE #cvo_replenishment
    (
      row_id INT IDENTITY(1, 1) ,
      replen_group INT ,
      location VARCHAR(10) ,
      queue_id INT ,
      part_no VARCHAR(30) ,
      part_desc VARCHAR(255) ,
      from_bin VARCHAR(20) ,
      to_bin VARCHAR(20) ,
      qty DECIMAL(20, 8)
    ); 


TRUNCATE TABLE #temp_bin_list;

INSERT  INTO #temp_bin_list
        ( replen_id ,
          bin_no ,
          part_no ,
          priority
        )
SELECT trd.replen_id ,
       trd.bin_no ,
       trd.part_no ,
	   0
FROM #temp_repl_display AS trd 


EXEC tdc_adhoc_bin_replenish_sp @location, @replen_group, 'ALL', @fill_to_max_ind, 0 -- commit = yes
 
---- SELECT * FROM #rep_bin_move_detail

INSERT INTO dbo.cvo_replenish_schedule
        ( replen_id ,
          bin_no ,
          part_no ,
          fill_opt ,
          priority ,
          station_id ,
          userid ,
          schedule_date
        )
SELECT  replen_id, to_bin, part_no, 0, isforced, '721',  'Auto-Replen', GETDATE()
FROM #rep_bin_move_detail 

-- SELECT * FROM dbo.cvo_replenish_schedule AS rs
END




GO
GRANT EXECUTE ON  [dbo].[cvo_auto_replenish_sp] TO [public]
GO
