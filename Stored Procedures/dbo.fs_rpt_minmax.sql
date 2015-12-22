SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_minmax] @part varchar(30),@type varchar(10), 
	@cat varchar(10), @loc varchar(10), @stat char(1) AS

declare @minstat char(1)
declare @maxstat char(1)
declare @scheduler char(1)
CREATE TABLE #tminmax(
	part_no         VARCHAR(30), 
	description     VARCHAR(255) NULL,
	location        VARCHAR(10), 
	in_stock        DECIMAL(20,8), 
	po_on_order     DECIMAL(20,8),
	qty_alloc       DECIMAL(20,8), 
	min_stock       DECIMAL(20,8),
	min_order       DECIMAL(20,8), 
	commit_ed       DECIMAL(20,8), 
	vendor          VARCHAR(12) NULL, 						-- mls 4/14/00 SCR 22710
	po_order_date   DATETIME NULL, 
	max_stock       DECIMAL(20,8), 
	hold_mfg        DECIMAL(20,8),
	hold_ord        DECIMAL(20,8),
	hold_rcv        DECIMAL(20,8),
	hold_xfr        DECIMAL(20,8),
	need_qty        DECIMAL(20,8),
	status          CHAR(1),
	buyer           VARCHAR(10) NULL,
	uom             CHAR(2) NULL
)
SELECT @minstat = 'A' 
SELECT @maxstat = 'Q'

if @stat = 'P' begin
  SELECT @minstat = 'N'
end
if @stat = 'M' begin
  SELECT @maxstat = 'M'
end
INSERT #tminmax (
	part_no, 
	description, 
	location, 
	in_stock, 
	po_on_order,
	qty_alloc, 
	min_stock,
	min_order, 
	commit_ed, 
	vendor, 
	po_order_date, 
	max_stock, 
	hold_mfg,
	hold_ord,
	hold_rcv,
	hold_xfr,
	need_qty,
	status,
	buyer,
	uom )
SELECT  part_no, 
	description, 
	location, 
	in_stock, 
	po_on_order,
	qty_alloc, 
	min_stock,
	min_order, 
	commit_ed + sch_alloc, 
	vendor, 
	null, 
	max_stock, 
	hold_mfg,
	hold_ord,
	hold_rcv,
	hold_xfr,
	min_stock - ( in_stock + po_on_order - commit_ed),
	status,
	buyer,
	uom
FROM    inventory 
WHERE   ( dbo.inventory.status >= @minstat AND
	  dbo.inventory.status <= @maxstat ) AND
	( @loc = '%' OR location like @loc ) AND
	( @part = '%' OR part_no like @part ) AND
	( @cat = '%' OR category like @cat ) AND
	( @type = '%' OR type_code like @type ) AND
	( ( min_stock >= 0  AND ( in_stock + po_on_order - commit_ed) < min_stock ) OR 
	  ( max_stock > 0 AND ( in_stock + po_on_order - commit_ed) > max_stock ) ) AND
        ( inventory.void is null OR inventory.void = 'N' )











































SELECT  part_no, 
	description, 
	location, 
	in_stock, 
	po_on_order,
	qty_alloc, 
	min_stock,
	min_order, 
	commit_ed, 
	vendor, 
	po_order_date, 
	max_stock, 
	hold_mfg,
	hold_ord,
	hold_rcv,
	hold_xfr,
	need_qty,
	@part,
	@type,
	@loc,
	@cat,
	@stat
FROM    #tminmax
ORDER BY location ASC, part_no ASC
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_minmax] TO [public]
GO
