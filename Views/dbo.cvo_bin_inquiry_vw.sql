SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- select * from cvo_bin_inquiry_vw where part_no = 'bcgcolink5316'

CREATE view [dbo].[cvo_bin_inquiry_vw]
as 
			SELECT  bm.usage_type_code, bm.group_code, b.location, b.bin_no,
				b.part_no, i.upc_code, i.[description], i.type_code, b.lot_ser, b.qty, 
				b.date_tran, b.date_expires, il.std_cost, il.std_ovhd_dolrs,
				il.std_util_dolrs, 
				round(((il.std_cost + il.std_ovhd_dolrs + il.std_util_dolrs) * b.qty),2) as	ext_cost,
				 isnull(pb.[primary],'N') primary_bin,
				 bm.last_modified_date, bm.modified_by
		    FROM tdc_bin_master bm (nolock)
		    inner join lot_bin_stock b (nolock)  
				on bm.bin_no = b.bin_no and bm.location = b.location
	        inner join inv_master i (nolock) on b.part_no = i.part_no
	        inner join inv_list il (nolock) 
				on il.part_no = i.part_no and il.location = bm.location
			LEFT OUTER JOIN tdc_bin_part_qty pb on b.bin_no = pb.bin_no and pb.location = b.location and pb.part_no = b.part_no
            WHERE 1=1

        union

        SELECT	distinct 
		m.usage_type_code, m.group_code, m.location, m.bin_no, s.part_no, i.upc_code,
		i.[description],  i.type_code, 
		'' lot_ser, 
		0 qty,
		getdate() date_tran, 
		GETDATE() date_expires ,
        il.std_cost, il.std_ovhd_dolrs,
				il.std_util_dolrs, 
				0 as ext_cost
				, s.[primary]
				, m.last_modified_date, m.modified_by
		
        FROM	tdc_bin_part_qty s (NOLOCK) 
        INNER JOIN	tdc_bin_master m (NOLOCK)
        ON		s.location = m.location   AND		s.bin_no = m.bin_no
        inner join inv_master i (nolock) on I.part_no = S.part_no
	        inner join inv_list il (nolock) 
				on il.part_no = i.part_no and il.location = S.location
      
        LEFT JOIN 
		lot_bin_stock l (NOLOCK)
        ON		s.location = l.location AND		s.part_no = l.part_no AND		s.bin_no = l.bin_no
        WHERE	l.location IS NULL AND		l.part_no IS NULL AND		l.bin_no IS NULL
    




GO
GRANT SELECT ON  [dbo].[cvo_bin_inquiry_vw] TO [public]
GO
