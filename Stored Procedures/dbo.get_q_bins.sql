SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/03/2012 - Display primary / secondary bins for the part even with no stock  
  
CREATE PROCEDURE [dbo].[get_q_bins] @pn varchar(30), @loc varchar(10)  AS  
  
SELECT distinct i.part_no,      -- mls 10/13/00 SCR 24581 start  
i.location,            
s.bin_no,     
s.lot_ser,  
s.date_expires,     
s.qty  
FROM lot_bin_stock  s (nolock), inv_list i (nolock)   
WHERE s.part_no = i.part_no and s.location = i.location and   
( s.part_no = @pn ) AND  ( s.location = @loc )  
UNION -- v1.0
SELECT	distinct 
		s.part_no, 
		s.location, 
		s.bin_no, 
		'' lot_ser, 
		GETDATE() date_expires ,
		0 qty
FROM	tdc_bin_part_qty s (NOLOCK) 
JOIN	tdc_bin_master m (NOLOCK)
ON		s.location = m.location
AND		s.bin_no = m.bin_no
LEFT JOIN 
		lot_bin_stock l (NOLOCK)
ON		s.location = l.location 
AND		s.part_no = l.part_no 
AND		s.bin_no = l.bin_no
WHERE	l.location IS NULL 
AND		l.part_no IS NULL 
AND		l.bin_no IS NULL
AND		( s.part_no = @pn ) AND  ( s.location = @loc )      
ORDER BY s.date_expires,  
s.bin_no ASC,     
s.lot_ser ASC        -- mls 10/13/00 SCR 24581 end  
  
GO
GRANT EXECUTE ON  [dbo].[get_q_bins] TO [public]
GO
