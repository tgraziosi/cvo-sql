SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_masterpack_consolidated_order_lines_vw.sql
Type:			View
Description:	Returns parts on consolidated orders
Developer:		Chris Tyler
Date:			8th April 2014

Revision History
2/7/2017 - tag - show line notes 

-- select * From cvo_masterpack_consolidated_order_lines_vw where consolidation_no = 18328

*/

CREATE VIEW [dbo].[cvo_masterpack_consolidated_order_lines_vw]
AS
    SELECT  b.consolidation_no ,
            a.part_no ,
            a.location ,
            a.part_type ,
            a.uom ,
            a.description ,
		-- '' item_note,
            notes.Item_notes item_note ,
            SUM(ordered) ord_qty
    FROM    dbo.ord_list a ( NOLOCK )
            INNER JOIN dbo.cvo_masterpack_consolidation_det b ( NOLOCK ) ON a.order_no = b.order_no
                                                              AND a.order_ext = b.order_ext
            LEFT OUTER JOIN ( SELECT DISTINCT
                                        mcd2.consolidation_no ,
                                        ol.part_no ,
                                        STUFF(( SELECT DISTINCT
                                                        '; ' + ISNULL(oln.note,'')
														FROM    ord_list oln
                                                        JOIN dbo.cvo_masterpack_consolidation_det
                                                        AS mcd ON mcd.order_ext = oln.order_ext
                                                              AND mcd.order_no = oln.order_no
                                                WHERE   mcd.consolidation_no = mcd2.consolidation_no
                                                        AND oln.part_no = ol.part_no
                                              FOR
                                                XML PATH('')
                                              ), 1, 1, '') Item_notes
                              FROM      dbo.cvo_masterpack_consolidation_det mcd2
                                        JOIN ord_list ol ON mcd2.order_ext = ol.order_ext
                                                            AND mcd2.order_no = ol.order_no
                            ) notes ON notes.consolidation_no = b.consolidation_no
                                       AND notes.part_no = a.part_no
    GROUP BY b.consolidation_no ,
            a.part_no ,
            a.location ,
            a.part_type ,
            a.uom ,
            a.description ,
            notes.Item_notes;

GO
GRANT SELECT ON  [dbo].[cvo_masterpack_consolidated_order_lines_vw] TO [public]
GO
