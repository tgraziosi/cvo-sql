SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 13/07/2016 - Performance  
-- v1.1 tg 8/5/2016 - insert blocks of 500 to minimize locking.

CREATE PROCEDURE [dbo].[adm_copy_loc_sp] @loc_source varchar(10),  
									@loc_dest varchar (10),  
									@part_no_from varchar(30),  
									@part_no_to varchar(30),  
									@vendor_from varchar(12),  
									@vendor_to varchar(12),  
									@type_from varchar(10),  
									@type_to varchar(10),  
									@master int,  
									@cbx_i int,  
									@cbx_t int,  
									@cbx_v int  
AS
BEGIN  
	-- DIRECTIVES
	SET NOCOUNT ON

	-- WORKING TABLE
	CREATE TABLE #parts_to_copy (
		from_location	varchar(10),
		to_location		varchar(10),
		part_no			varchar(30))

	CREATE TABLE #inv_list (
		part_no				varchar(30), 
		location			varchar(10), 
		bin_no				varchar(12), 
		avg_cost			decimal(20,8), 
		avg_direct_dolrs	decimal(20,8), 
		avg_ovhd_dolrs		decimal(20,8), 
		avg_util_dolrs		decimal(20,8), 
		in_stock			decimal(20,8), 
		hold_qty			decimal(20,8), 
		min_stock			decimal(20,8), 
		max_stock			decimal(20,8),  
		min_order			decimal(20,8), 
		issued_mtd			decimal(20,8), 
		issued_ytd			decimal(20,8), 
		lead_time			int, 
		status				char(1), 
		labor				decimal(20,8), 
		qty_year_end		decimal(20,8), 
		qty_month_end		decimal(20,8), 
		qty_physical		decimal(20,8), 
		entered_who			varchar(20), 
		entered_date		datetime, 
		void				char(1), 
		void_who			varchar(20), 
		void_date			datetime,
		std_cost			decimal(20,8), 
		std_labor			decimal(20,8), 
		std_direct_dolrs	decimal(20,8), 
		std_ovhd_dolrs		decimal(20,8), 
		std_util_dolrs		decimal(20,8), 
		setup_labor			decimal(20,8), 
		freight_unit		decimal(20,8), 
		note				varchar(255), 
		cycle_date			datetime, 
		acct_code			varchar(8), 
		eoq					decimal(20,8), 
		dock_to_stock		int, 
		order_multiple		decimal(20,8), 
		abc_code			char(1), 
		abc_code_frozen_flag int, 
		rank_class			varchar(1), 
		po_uom				char(2), 
		so_uom				char(2))

	-- PROCESSING
	IF (@master = 0) -- Source location specified   
	BEGIN  

		INSERT	#parts_to_copy (from_location, to_location, part_no)
		SELECT  @loc_source, @loc_dest, a.part_no
		FROM	inv_list a (NOLOCK)
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	((a.part_no BETWEEN @part_no_from AND @part_no_to ) OR 1 = @cbx_i)  
		AND		((b.vendor BETWEEN @vendor_from AND @vendor_to ) OR 1 = @cbx_v)  
		AND		((b.type_code BETWEEN @type_from AND @type_to) OR 1 = @cbx_t)  
		AND		a.location = @loc_source

		DELETE	a
		FROM	#parts_to_copy a
		JOIN	inv_list b (NOLOCK)
		ON		a.to_location = b.location
		AND		a.part_no = b.part_no

		CREATE INDEX #parts_to_copy_ind0 ON #parts_to_copy(from_location, part_no)


		INSERT INTO #inv_list ( part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
			min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
			std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
			abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom)   
		SELECT  ptc.part_no, ptc.to_location, a.bin_no, 0, 0, 0, 0, 0, a.hold_qty, a.min_stock, a.max_stock, a.min_order, 0, 0, a.lead_time, a.status, a.labor, 0, 0, 0, '',
				GETDATE(), 'N', NULL, NULL, a.std_cost, a.std_labor, a.std_direct_dolrs, a.std_ovhd_dolrs, a.std_util_dolrs, a.setup_labor, a.freight_unit, a.note, a.cycle_date, 
				a.acct_code, a.eoq, a.dock_to_stock, a.order_multiple, a.abc_code, a.abc_code_frozen_flag, a.rank_class, a.po_uom, a.so_uom   
		FROM	#parts_to_copy ptc
		JOIN	inv_list a (NOLOCK)
		ON		ptc.from_location = a.location
		AND		ptc.part_no = a.part_no
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no  

		WHILE EXISTS (SELECT 1 FROM #inv_list)
		begin
			INSERT	inv_list ( part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
				min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
				std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
				abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom)
			SELECT	TOP (500) part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
				min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
				std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
				abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom
			FROM	#inv_list

			DELETE	a
			FROM	#inv_list a
			JOIN	inv_list b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
		END
        
	END  
  
	IF (@master = 1)   
	BEGIN  
   
		INSERT	#parts_to_copy (from_location, to_location, part_no)
		SELECT  MIN(a.location), @loc_dest, a.part_no
		FROM	inv_list a (NOLOCK)
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no
		WHERE	((a.part_no BETWEEN @part_no_from AND @part_no_to ) OR 1 = @cbx_i)  
		AND		((b.vendor BETWEEN @vendor_from AND @vendor_to ) OR 1 = @cbx_v)  
		AND		((b.type_code BETWEEN @type_from AND @type_to) OR 1 = @cbx_t)  
		AND		a.location <> @loc_dest
		GROUP BY a.part_no

		DELETE	a
		FROM	#parts_to_copy a
		JOIN	inv_list b (NOLOCK)
		ON		a.to_location = b.location
		AND		a.part_no = b.part_no

		CREATE INDEX #parts_to_copy_ind0 ON #parts_to_copy(from_location, part_no)

		INSERT INTO #inv_list ( part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
			min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
			std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
			abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom)   
		SELECT	ptc.part_no, ptc.to_location, 'N/A', 0, 0, 0, 0 , 0 , 0 , 0 , 0.0, 0.0, 0 , 0 , 0, a.status, 0, 0, 0, 0, '', GETDATE(), 'N', NULL, NULL, 0, 0 , 0, 0,  
				0, a.setup_labor, a.freight_unit, NULL, '', b.account, 0, 0, 0.0, a.abc_code, a.abc_code_frozen_flag, 'N', b.uom, b.uom 
		FROM	#parts_to_copy ptc
		JOIN	inv_list a (NOLOCK)
		ON		ptc.from_location = a.location
		AND		ptc.part_no = a.part_no
		JOIN	inv_master b (NOLOCK)
		ON		a.part_no = b.part_no 
 
 		WHILE EXISTS (SELECT 1 FROM #inv_list)
		begin
			INSERT INTO inv_list ( part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
				min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
				std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
				abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom)   
			SELECT	part_no, location, bin_no, avg_cost, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, in_stock, hold_qty, min_stock, max_stock,  
					min_order, issued_mtd, issued_ytd, lead_time, status, labor, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, void_who, void_date,
					std_cost, std_labor, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, setup_labor, freight_unit, note, cycle_date, acct_code, eoq, dock_to_stock, order_multiple, 
					abc_code, abc_code_frozen_flag, rank_class, po_uom, so_uom
			FROM	#inv_list

			DELETE	a
			FROM	#inv_list a
			JOIN	inv_list b (NOLOCK)
			ON		a.location = b.location
			AND		a.part_no = b.part_no
		end


		DELETE	a
		FROM	#parts_to_copy a
		JOIN	inv_xfer b (NOLOCK)
		ON		a.to_location = b.location
		AND		a.part_no = b.part_no

		INSERT	inv_xfer (part_no, location, commit_ed, xfer_mtd, xfer_ytd, hold_xfr, transit, commit_to_loc)
		SELECT	ptc.part_no, ptc.to_location, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  
		FROM	#parts_to_copy ptc	

 	END 

	DROP TABLE #parts_to_copy 
	DROP TABLE #inv_list


END

GO
GRANT EXECUTE ON  [dbo].[adm_copy_loc_sp] TO [public]
GO
