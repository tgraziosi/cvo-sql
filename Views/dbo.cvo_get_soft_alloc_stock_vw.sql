SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- select * From cvo_get_soft_alloc_stock_vw where order_no = 1822190


-- SELECT sum(sa_stock) from cvo_get_soft_alloc_stock_vw where location = '001' and part_no = 'bcbiabla5115'
-- SELECT * from cvo_get_soft_alloc_stock_vw where location = '001' and part_no = 'bcbiabla5115'
-- select * from dbo.cvo_soft_alloc_hdr where order_no = 1822190

CREATE view [dbo].[cvo_get_soft_alloc_stock_vw]
-- tag 5/20/2013 - add custom -4's
AS
	-- v1.2
	SELECT	distinct a.status, a.order_no, a.order_ext, a.part_no, a.line_no, a.location,
	sa_stock = CASE WHEN c.type_code = 'CASE' THEN 0 ELSE ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) END
	--  - CASE WHEN a.change >= 1 THEN ISNULL((b.qty),0) ELSE 0 END
	, 0 as alloc_stock,
	bo_stock = CASE WHEN C.type_code = 'CASE' THEN 0 ELSE CASE when sh.bo_hold = 1 then isnull((case when a.deleted=1 then a.quantity*-1 else a.quantity end),0) else 0 END END
	
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	inner join dbo.cvo_soft_alloc_hdr sh (nolock)
		on sh.order_no =  a.order_no and sh.order_ext = a.order_ext and sh.status = a.status
		JOIN INV_MASTER C (NOLOCK) ON C.part_no = a.part_no
	WHERE	a.status  NOT IN (-2,-3) -- IN (0, 1, -1, -4) and a.kit_part = 0
	
		--	SELECT	@alloc_stock = SUM(ISNULL((CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0) - CASE WHEN a.change >= 1 THEN CASE WHEN a.deleted = 1 THEN (ISNULL((b.qty),0) * -1) ELSE ISNULL((b.qty),0) END ELSE 0 END) -- v1.4
		--FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
		--LEFT JOIN (SELECT order_no, order_ext, line_no, part_no, SUM(qty) qty FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_type = 'S' GROUP BY order_no, order_ext, line_no, part_no) b
		--ON	a.order_no = b.order_no
		--AND	a.order_ext = b.order_ext
		--AND	a.part_no = b.part_no
		--AND a.line_no = b.line_no
		--WHERE	a.status NOT IN (-2,-3) -- v1.5 IN (0, 1, -1)
		--AND		a.location = @location
		--AND		a.part_no = @part_no





GO
GRANT REFERENCES ON  [dbo].[cvo_get_soft_alloc_stock_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_get_soft_alloc_stock_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_get_soft_alloc_stock_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_get_soft_alloc_stock_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_get_soft_alloc_stock_vw] TO [public]
GO
