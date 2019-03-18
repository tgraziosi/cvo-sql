SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_cf_get_tab_data_sp] @user_spid int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id				int,
			@last_row_id		int,
			@component_type		varchar(20),
			@orig_component		varchar(30),
			@required_qty		decimal(20,8),
			@location			varchar(10),
			@order_part_type	varchar(5),
			@order_part_no		varchar(30),
			@line_no			int,
			@category			varchar(20),
			@style				varchar(30),
			@attribute			varchar(30),
			@alternate_done		int,
			@qty_in_stock		decimal(20,8),
			@sa_qty				decimal(20,8),
			@colour				varchar(40),
			@prev_colour		varchar(40),
			@order_by			int

	-- WORKING TABLES
	CREATE TABLE #tab_data_in (
		row_id			int IDENTITY(1,1),
		component_type	varchar(20),
		selected_qty	decimal(20,8))

	-- PROCESSING
	INSERT	#tab_data_in (component_type, selected_qty)
-- v1.1	SELECT	CASE WHEN LEFT(component_type,7) = 'TEMPLE-' THEN LEFT(component_type,6) ELSE component_type END,
	SELECT	CASE WHEN (component_type = 'TEMPLE-L' OR component_type = 'TEMPLE-R') THEN 'TEMPLE' ELSE component_type END, -- v1.1
			-- v1.2 SUM(required_qty * selected)
			SUM(selected_qty * selected) -- v1.2
	FROM	cvo_cf_process_select (NOLOCK)
	WHERE	user_spid = @user_spid
	AND		component_type <> 'BLANK_LINE'
-- v1.1	GROUP BY CASE WHEN LEFT(component_type,7) = 'TEMPLE-' THEN LEFT(component_type,6) ELSE component_type END
	GROUP BY CASE WHEN (component_type = 'TEMPLE-L' OR component_type = 'TEMPLE-R') THEN 'TEMPLE' ELSE component_type END -- v1.1

	SELECT	row_id, component_type, CAST(selected_qty as int) selected_qty 
	FROM	#tab_data_in 
	ORDER BY row_id

	DROP TABLE #tab_data_in



END
GO
GRANT EXECUTE ON  [dbo].[cvo_cf_get_tab_data_sp] TO [public]
GO
