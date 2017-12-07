SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[get_inv_loc] @strsort varchar(50), @sort char(1), @loc varchar(10), 
 @void char(1), @stat char(1), @type varchar(10), 
 @lastkey varchar(30), @iobs int, @non_sellable char(1) = 'Y', @org_id varchar(30) = '', @module varchar(10) = '',
@sec_level int = 4 AS

-- v1.0 CB 29/03/2011 - Changed from using ROWCOUNT to TOP as it was affecting the underlying functions
-- v1.1 CB 19/10/2011 - Performance enhancement
-- v2.0 TM 10/27/2011 - When called from Inventory (module = '') ignore the check on Obsolete
-- v2.1 CB 07/11/2011 - Remove inv_produce joins as per TM request
-- v2.2 CB 02/05/2012 - If @type is FRAME then treat as FRAME OR SUN
-- v2.3	CT 18/07/2012 - Remove qty on replishment moves from avail qty	
-- v2.4 CB 04/01/2013 - Issue #1051 - Need to exclude soft allocations
-- v2.5 CB 07/01/2013 - Issue #1051 - if available less than zero show zero.
-- v2.6 CB 14/01/2013 - Issue #1075 - Remove v2.5
-- v2.7 CB 16/04/2013 - Issue #1212 - replicate columns as per inventory screen
-- v2.8 CB 07/10/2013	Issue #1385 - non alloc bin qty must exclude what has been allocated
-- v2.9 CB 16/06/2014 - Performance
-- v3.0 CB 18/08/2014 - Performance
-- v3.1 CB 02/11/2017 - #1649 - Exclude cases from soft allocation

DECLARE	@sa_qty			decimal(20,8), -- v2.4
		@repl_qty		decimal(20,8), -- v2.7
		@non_alloc		decimal(20,8), -- v2.7
		@repl_non_sa	decimal(20,8), -- v2.7
		@available		decimal(20,8), -- v2.7		
		@type_code		varchar(10) -- v3.1

-- v2.2 Create table to hold type
CREATE TABLE #types (type_code varchar(10))

-- v2.2 if a type is specified insert it into the working table
IF @type <> '%'
BEGIN
	INSERT	#types
	SELECT	@type

	-- if the type is frame then add SUN to the working table 
	IF @type = 'FRAME'
	BEGIN
		INSERT	#types
		SELECT	'SUN'
	END
END

--set rowcount 100
declare @minstat char(1)
declare @maxstat char(1)

select @org_id = isnull(@org_id,'')
SELECT @minstat = 'A' 
SELECT @maxstat = 'R'

if @stat = 'A' begin
 SELECT @maxstat = 'Q'
end

if @stat = 'M' begin
 SELECT @maxstat = 'M'
end

if @stat = 'P' begin
 SELECT @minstat = 'N'
 SELECT @maxstat = 'Q'
end

if @stat = 'R' begin
 SELECT @minstat = 'R'
 SELECT @maxstat = 'R'
end

if @stat = 'V' begin
 SELECT @minstat = 'V'
 SELECT @maxstat = 'V'
end

if @stat = 'K' begin
 SELECT @minstat = 'K'
 SELECT @maxstat = 'K'
end

create table #temp_inv (
part_no varchar(30), description varchar(255) NULL, category varchar(10) NULL,
sku_no varchar(30) NULL, in_stock decimal(20,8), type_code varchar(10) NULL,
status char(1) NULL, commit_ed decimal(20,8), po_on_order decimal(20,8), sch_alloc decimal(20,8), xfer_committed decimal(20,8),
status_type char(30) NULL, 
non_alloc decimal(20,8) default(0), repl_non_sa decimal(20,8) default(0), repl_qty decimal(20,8) default(0), -- v2.7
row_id int identity(1,1))

create index r1 on #temp_inv(row_id,part_no)				-- mls 11/8/02 SCR 30247

if @sort='N' begin

	-- v1.1 Performance Enhancements
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd)end in_stock, -- v2.8
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
-- v2.8	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	(m.part_no >= @strsort OR @strsort IS NULL) 
	AND		(l.location = @loc)  
	AND		(m.void IS NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.part_no


/* v1.1 Original
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed , po_on_order, sch_alloc, x.commit_ed				-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where (i.part_no >= @strsort OR @strsort is null) and (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and
 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.part_no
*/

end  
 
 
if @sort='D' begin
	-- v1.1 Performance Enhancements
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd )end in_stock, -- v2.8
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
-- v2.8	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	((m.description > @strsort OR @strsort IS NULL) OR (m.description = @strsort AND m.part_no >= @lastkey) ) 
	AND		(l.location = @loc) 
	AND		(m.void IS NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.description,m.part_no

/* v1.1 Original
insert into #temp_inv
(part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed, po_on_order, sch_alloc, x.commit_ed					-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where ( (i.description > @strsort OR @strsort is null) OR (i.description = @strsort and i.part_no >= @lastkey) ) and
 (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and
 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.description,i.part_no
*/
end 
 
if @sort='K' begin
	select @strsort = '%' + @strsort + '%'

	-- v1.1 Performance Enhancement
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd)end in_stock, -- v2.8 
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	(m.description LIKE @strsort OR @strsort IS NULL) 
	AND		(m.part_no >= @lastkey) 
	AND		(l.location = @loc) 
	AND		(m.void IS NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.part_no

/* v1.1 Original
insert into #temp_inv
(part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed , po_on_order, sch_alloc, x.commit_ed					-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where (i.description like @strsort OR @strsort is null) AND
 (i.part_no >= @lastkey) and
 (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and
 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.part_no
*/
end 
 
if @sort='S' begin

	-- v1.1 Performance Enhancements
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd)end in_stock, -- v2.8
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
-- v2.8	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	((m.sku_no > @strsort OR @strsort IS NULL) OR (m.sku_no = @strsort AND m.part_no >= @lastkey)) 
	AND		(l.location = @loc) 
	AND		(m.void IS NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.sku_no,m.part_no

/* v1.1 Original
insert into #temp_inv
(part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed , po_on_order, sch_alloc, x.commit_ed					-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where ( (i.sku_no > @strsort OR @strsort is null) OR (i.sku_no = @strsort and i.part_no >= @lastkey) ) and
 (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and

 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.sku_no,i.part_no
*/
end  

if @sort='U' begin

	-- v1.1 Performance Enhancements
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd)end in_stock,  -- v2.8
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	((m.upc_code > @strsort OR @strsort IS NULL) OR (m.upc_code = @strsort AND m.part_no >= @lastkey) ) 
	AND		(l.location = @loc) 
	AND		(m.void is NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.upc_code,m.part_no


/* v1.1 Original
insert into #temp_inv
(part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed , po_on_order, sch_alloc, x.commit_ed					-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where ( (i.upc_code > @strsort OR @strsort is null) OR (i.upc_code = @strsort and i.part_no >= @lastkey) ) and 
 (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and
 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.upc_code,i.part_no
*/
end  
 

if @sort='C' begin

	-- v1.1 Performance Enhancements
	INSERT INTO #temp_inv (part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
	SELECT	TOP 100 m.part_no, m.description, m.category, m.sku_no,
-- v2.8		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
			case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd)end in_stock, -- v2.8
			m.type_code, m.status, s.commit_ed, r.po_on_order, 0, x.commit_ed
-- v2.1		case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end in_stock, 
-- v2.1		m.type_code, m.status, s.commit_ed, r.po_on_order, p.sch_alloc, x.commit_ed
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
-- v2.1	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
-- v2.8	LEFT JOIN dbo.f_get_excluded_bins(1) z on l.location = z.location AND l.part_no = z.part_no
	WHERE	((m.category > @strsort OR @strsort IS NULL) OR (m.category = @strsort AND m.part_no >= @lastkey)) 
	AND		(l.location = @loc) 
	AND		(m.void IS NULL OR m.void LIKE @void) 
	AND		(@type = '%' OR m.type_code IN (SELECT type_code FROM #types)) -- v2.2
--	AND		(@type = '%' OR m.type_code LIKE @type) -- v2.2
	AND		(m.status >= @minstat AND m.status <= @maxstat ) 
	AND		m.obsolete <= @iobs 
	ORDER BY m.category,m.part_no

/* v1.1 Original
insert into #temp_inv
(part_no, description, category, sku_no, in_stock, type_code, status, commit_ed, po_on_order, sch_alloc, xfer_committed)
select TOP 100 i.part_no, description, category, sku_no, in_stock, 
 type_code, status, i.commit_ed , po_on_order, sch_alloc, x.commit_ed					-- mls 2/15/01 SCR 25952
 from inventory i ( NOLOCK ), inv_xfer x (nolock)						-- mls 2/15/01 SCR 25952
 where ( (i.category > @strsort OR @strsort is null) OR (i.category = @strsort and i.part_no >= @lastkey) ) and
 (i.location = @loc) and 
 (i.location in (select location from dbo.locations (NOLOCK))) and
 --(i.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level)) or @org_id = '') and
 (i.part_no = x.part_no and i.location = x.location) and				-- mls 2/15/01 SCR 25952
 (void is NULL OR void like @void) and
 (@type = '%' OR i.type_code like @type) and
 (status >= @minstat AND status <= @maxstat ) and
 obsolete <= @iobs 
 order by i.category,i.part_no
*/
end 



--v2.0
IF @module = 'soe'																								--v2.0
	BEGIN																										--v2.0
		if @non_sellable <> 'Y'																					--v2.0
		begin																									--v2.0
			delete from #temp_inv																				--v2.0
			 where part_no in (select part_no from inv_master (nolock) where non_sellable_flag = 'Y')			--v2.0
		end																										--v2.0
	END																											--v2.0
--v2.0

DECLARE @barcoded char(1), @part_no varchar(30)

select @barcoded = isnull((select 'Y' from config (nolock) where flag = 'BARCODING' and upper(value_str) like 'Y%'),'N')

create table #t1 (location varchar(10), part_no varchar(30), allocated_amt decimal(20,8), quarantined_amt decimal(20,8), sce_version varchar(10), sa_qty decimal(20,8)) -- v2.4 add sa_qty
create index t1 on #t1(part_no)								-- mls 11/8/02 SCR 30247

if @barcoded = 'Y'
begin

	-- v3.0 Start
	DECLARE @last_part_no varchar(30)

	SET @last_part_no = ''

	SELECT	TOP 1 @part_no = part_no,
			@type_code = type_code -- v3.1
	FROM	#temp_inv
	WHERE	part_no > @last_part_no
	ORDER BY part_no ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

--	  declare inv1_cur cursor local for
--	  select distinct part_no
--	  from #temp_inv
--	  order by part_no
--	
--	  open inv1_cur
--
--	  Fetch Next from inv1_cur into @part_no  
--	  
--	  While @@FETCH_STATUS = 0
--	  begin
		-- v3.0 End

		insert #t1 (location, part_no, allocated_amt, quarantined_amt, sce_version)
		exec tdc_get_alloc_qntd_sp @loc, @part_no

		-- v2.4 Start
		-- v3.1 Start
		IF (@type_code = 'CASE')
		BEGIN
			SET @sa_qty = 0
		END
		ELSE
		BEGIN
			SET @sa_qty = 0

			SELECT	@sa_qty = SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END)
			FROM	cvo_soft_alloc_det a (NOLOCK)
		--	JOIN	cvo_orders_all b (NOLOCK)
		--	ON		a.order_no = b.order_no
		--	AND		a.order_ext = b.ext
			WHERE	a.location = @loc
			AND		a.part_no = @part_no
			AND		a.order_no <> 0
			AND		a.status IN (0,1)

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0

			SELECT	@sa_qty = @sa_qty + ISNULL(SUM(a.quantity),0)
			FROM	cvo_soft_alloc_det a (NOLOCK)
			WHERE	a.location = @loc
			AND		a.part_no = @part_no
			AND		a.order_no = 0
			AND		a.status IN (1)

			IF (@sa_qty IS NULL)
				SET @sa_qty = 0
		END
		-- v3.1 End

		UPDATE	#t1
		SET		sa_qty = @sa_qty
		WHERE	location = @loc
		AND		part_no = @part_no
		-- v2.4 End
		
		-- v2.7 Start
		SET @repl_qty = 0
		SET @non_alloc = 0
		SET @available = 0
		SET @repl_non_sa = 0

		SELECT @repl_qty = SUM(qty) FROM cvo_replenishment_qty (NOLOCK) WHERE location = @loc AND part_no = @part_no
		
		-- v2.8 Start
	--	SELECT @non_alloc = SUM(qty) FROM cvo_lot_bin_stock_exclusions (NOLOCK) WHERE location = @loc AND part_no = @part_no	
		SELECT	@non_alloc = SUM(a.qty) - ISNULL(SUM(b.qty),0.0) 
		FROM	cvo_lot_bin_stock_exclusions a (NOLOCK)
		LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @loc 
		AND		a.part_no = @part_no	
		-- v2.8 End

		IF (@repl_qty IS NULL)
			SET @repl_qty = 0

		IF (@non_alloc IS NULL)
			SET @non_alloc = 0

		SELECT	@available = in_stock - t.allocated_amt - t.sa_qty - (t.quarantined_amt + @repl_qty ) - @non_alloc
		FROM	#temp_inv i
		LEFT OUTER JOIN #t1 t on i.part_no = t.part_no
		WHERE	i.part_no = @part_no

		IF (@available < 0)
		BEGIN
			IF (@repl_qty > 0) 
			BEGIN
				SET @repl_non_sa = @repl_qty + @available
				IF (@repl_non_sa < 0)
					SET @repl_non_sa = 0
				IF (@repl_non_sa > @repl_qty) 
					SET @repl_non_sa =  @repl_qty
			END
		END
		ELSE
			SET @repl_non_sa = @repl_qty			

		UPDATE	#temp_inv
		SET		non_alloc = @non_alloc, 
				repl_non_sa = @repl_non_sa, 
				repl_qty = @repl_qty
		WHERE	part_no = @part_no

				
		-- v2.7 End

		-- v3.0 Start
		SET @last_part_no = @part_no

		SELECT	TOP 1 @part_no = part_no,
				@type_code = type_code -- v3.1
		FROM	#temp_inv
		WHERE	part_no > @last_part_no
		ORDER BY part_no ASC

--	    Fetch Next from inv1_cur into @part_no  
--	  end
--	 
--	  close inv1_cur
--	  deallocate inv1_cur

	END
end

select TOP 100 i.part_no, i.description, i.category, i.sku_no, 
isnull(left(t.sce_version,1),'N'),					-- mls 4/12/05 SCR 34525
convert(varchar(30),convert(money,i.in_stock),1),
convert(varchar(30),convert(money,i.commit_ed + i.xfer_committed),1),
convert(varchar(30),convert(money,t.sa_qty),1),
convert(varchar(30),convert(money,
  case when isnull(left(t.sce_version,1),'N') <> 'N' then isnull(t.allocated_amt,0)
  else i.in_stock - (i.commit_ed + i.sch_alloc + i.xfer_committed) end),1),
convert(varchar(30),convert(money,
  case when isnull(left(t.sce_version,1),'N') <> 'N' then isnull(t.quarantined_amt,0)
  else i.po_on_order end),1), 
 case when isnull(left(t.sce_version,1),'N') <> 'N' then
-- CASE WHEN (i.in_stock - t.allocated_amt - t.sa_qty -
--    case when isnull(left(t.sce_version,1),'N') = 'W' then (t.quarantined_amt + ISNULL(replen.qty,0)) else (i.xfer_committed + i.sch_alloc) end) < 0 then convert(varchar(30),0.00) else
-- v2.7 Start
  convert(varchar(30),convert(money, 
	case when (repl_qty - repl_non_sa) > 0 THEN  (i.in_stock - t.allocated_amt - t.sa_qty - i.non_alloc - -- v2.8
    case when isnull(left(t.sce_version,1),'N') = 'W' then (t.quarantined_amt + ISNULL(replen.qty,0)) else (i.xfer_committed + i.sch_alloc) end ) + (repl_qty - repl_non_sa) ELSE
		i.in_stock - t.allocated_amt - t.sa_qty - i.non_alloc - -- v2.8
		case when isnull(left(t.sce_version,1),'N') = 'W' then (t.quarantined_amt + ISNULL(replen.qty,0)) else (i.xfer_committed + i.sch_alloc) end END )) --end	-- v2.3 v2.4 add sa_qty
  else convert(varchar(30),i.type_code) end ,
-- v2.7 end
case when isnull(left(t.sce_version,1),'N') <> 'N' then
  convert(varchar(30),convert(money,i.po_on_order), 1)
  else convert(varchar(30),i.status_type) end,

case when isnull(left(t.sce_version,1),'N') <> 'N' then i.type_code else '' end,
case when isnull(left(t.sce_version,1),'N') <> 'N' then i.status_type else '' end,
convert(varchar(30),convert(money,i.non_alloc),1), -- v2.7
convert(varchar(30),convert(money,i.repl_non_sa),1), -- v2.7
convert(varchar(30),convert(money,i.repl_qty),1) -- v2.7
from 
(select TOP 100 part_no , description , category ,
  sku_no , in_stock , type_code ,
  status , commit_ed , po_on_order , sch_alloc ,
  case isnull(status,'')
    when 'A' then 'Active'
    when 'C' then 'Custom Kit'				-- mls 5/3/04
    when 'P' then 'Purchase'
    when 'M' then 'Make'
    when 'V' then 'Non Qty Bearing'
    when 'R' then 'Resource'
    when 'K' then 'Auto-Kit'
    when 'H' then 'Make-Routed'
    when 'Q' then 'Pur/Outsource'
    else '' end,row_id, xfer_committed, non_alloc, repl_non_sa, repl_qty -- v2.7
  from #temp_inv) as i(part_no , description , category ,
    sku_no , in_stock , type_code ,
    status , commit_ed , po_on_order , sch_alloc ,status_type, row_id, xfer_committed, non_alloc, repl_non_sa, repl_qty) -- v2.7	-- mls 11/8/02 SCR 30247 
 left outer join #t1 t on i.part_no = t.part_no					-- mls 11/8/02 SCR 30247
 LEFT JOIN dbo.cvo_replenishment_qty replen on replen.location = @loc AND i.part_no = replen.part_no	-- v2.3  
order by row_id

drop table #temp_inv
drop table #t1

set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[get_inv_loc] TO [public]
GO
