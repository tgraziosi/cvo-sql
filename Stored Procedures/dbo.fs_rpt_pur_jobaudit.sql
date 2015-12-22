SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_pur_jobaudit] @prodno int AS

CREATE TABLE #temppur (
   po_no varchar(16),
   po_stat char(1),
   prod_no int NULL,
   prod_part varchar(30) NULL,
   prod_desc varchar(255) NULL,
   prod_stat char(1) NULL 
)
INSERT #temppur
SELECT po_no, status, prod_no, '', '', ''
FROM   purchase_all 
WHERE  (status='H' or status='O') and 
       ( ( @prodno=0 and prod_no<>0 ) or (@prodno>0 and prod_no=@prodno) )

UPDATE #temppur SET prod_stat=status, prod_part=part_no, prod_desc=description
FROM   produce_all WHERE produce_all.prod_no=#temppur.prod_no and produce_all.prod_ext=0

DELETE #temppur WHERE prod_stat < 'R' or prod_stat is null

SELECT t.prod_no, t.prod_part, t.prod_desc, 
       t.prod_stat, r.po_no, r.part_no, p.description,
       r.status, r.release_date, r.quantity, r.received
FROM   #temppur t, pur_list p, releases r
WHERE  t.po_no=p.po_no and t.po_no=r.po_no and
       p.line = case when isnull(r.po_line,0)=0 then p.line else r.po_line end and		-- mls 5/15/01 SCR 6603
       p.part_no=r.part_no and r.status='O'
ORDER BY t.prod_no, r.po_no, r.part_no, r.release_date
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_pur_jobaudit] TO [public]
GO
