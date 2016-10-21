SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- select * from cvo_adrec_vw where date_received > '1/1/2016'

CREATE VIEW [dbo].[cvo_adrec_vw]
AS
    SELECT  r.receipt_no ,
            r.po_key ,
            p.line ,
            r.vendor ,
			av.vendor_name,
            r.location ,
            r.part_no ,
            p.description ,
            r.unit_measure ,
            p.qty_ordered ,
            qty_received = r.quantity ,
            date_received = r.recv_date ,
            qc_desc = CASE r.qc_flag
                        WHEN 'N' THEN 'No'
                        WHEN 'Y' THEN 'Yes'
                        WHEN 'F' THEN 'No'					-- mls 02/21/03 SCR 29078
                        ELSE ''
                      END ,
            r.status ,
            status_desc = CASE r.status
                            WHEN 'R' THEN 'Received'
                            WHEN 'S' THEN 'Matched'
                            ELSE ''
                          END ,
            r.unit_cost ,
            r.unit_cost * r.quantity AS ext_val_recd ,
            r.part_type ,
 -- r.sku_no , 
            r.who_entered ,
            r.voucher_no ,
 -- i.tolerance_cd,
 
 	-- EL - 051214 -- Air or Ocean Delivery Method
            CASE WHEN p.ship_via_method IS NULL
                      AND pa.ship_via_method IS NULL THEN 'NA'
                 WHEN p.ship_via_method = 0 THEN 'None'
                 WHEN p.ship_via_method = 1 THEN 'Air'
                 WHEN p.ship_via_method = 2 THEN 'Ocean'
                 WHEN p.ship_via_method IS NULL
                      AND pa.ship_via_method = 0 THEN 'None'
                 WHEN p.ship_via_method IS NULL
                      AND pa.ship_via_method = 1 THEN 'Air'
                 WHEN p.ship_via_method IS NULL
                      AND pa.ship_via_method = 2 THEN 'Ocean'
                 ELSE 'XXXXXXXX'
            END AS x_method ,
            i.type_code , -- 12/8/2014 - tag -- acctg request to add
	-- add currency information
            r.nat_curr ,
            r.oper_factor ,
            r.oper_cost ,
            r.curr_factor ,
            r.curr_cost

--x_receipt_no=r.receipt_no ,
--x_po_key=r.po_key , 
--x_line=p.line,
--x_qty_ordered=p.qty_ordered , 
--x_qty_received = r.quantity , 
--x_date_received = ((datediff(day, '01/01/1900', r.recv_date) + 693596)) + (datepart(hh,r.recv_date)*.01 + datepart(mi,r.recv_date)*.0001 + datepart(ss,r.recv_date)*.000001),
--x_unit_cost=r.unit_cost 
    FROM    receipts_all r
            INNER JOIN pur_list p ( NOLOCK ) ON r.po_key = p.po_key
                                          AND r.part_no = p.part_no
                                          AND p.line = CASE WHEN ISNULL(r.po_line,
                                                              0) = 0
                                                            THEN p.line
                                                            ELSE r.po_line
                                                       END	-- mls 5/9/01  SCR 6603 
            LEFT OUTER JOIN inv_master i ( NOLOCK ) ON i.part_no = r.part_no							-- mls 2/14/01 SCR 25365
                                                       AND r.part_type = 'P'
            INNER JOIN purchase_all pa ( NOLOCK ) ON pa.po_key = p.po_key
			INNER JOIN dbo.adm_vend AS av ON av.vendor_code = r.vendor;
 -- EL - 051214 -- Air or Ocean Delivery Method

  
 




GO
GRANT REFERENCES ON  [dbo].[cvo_adrec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adrec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adrec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adrec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adrec_vw] TO [public]
GO
