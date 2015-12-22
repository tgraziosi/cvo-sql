SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_style_status_vw] 
as

select c.collection, c.style, c.color_desc, c.pom_date, c.tl, c.style_pom_status,
c.qty_avl, c.in_stock, c.e12_wu, c.po_on_order, '' as [TB NOTES], '' as [TG NOTES], c.active, c.eff_date, c.obs_date, ROWNUM From  
(
select row_number() over(partition by collection, style, color_desc order by collection, style, color_desc, eff_date desc) as rownum,
 * From cvo_pom_tl_status
) as c 
where rownum <=2
and pom_date >= dateadd(yy, -2, dateadd(yy, datediff(yy,0, getdate()), 0))


GO
GRANT REFERENCES ON  [dbo].[cvo_style_status_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_style_status_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_style_status_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_style_status_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_style_status_vw] TO [public]
GO
