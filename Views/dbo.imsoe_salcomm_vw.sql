SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[imsoe_salcomm_vw] as
SELECT company_code,
		order_no,
       ext,
       salesperson,
       sales_comm,
       percent_flag,
       exclusive_flag,
       split_flag,
       note,
       line_no,
       line_note,
	   time_entered,
       batch_no,
       dirty_flag,
       record_status_1,
       record_status_2,
       process_status,
       record_type,
       record_id_num,
        [User_ID]
FROM  CVO_Control.dbo.imsoe
where (record_type & 0x00000008) > 0



GO
GRANT REFERENCES ON  [dbo].[imsoe_salcomm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imsoe_salcomm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imsoe_salcomm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imsoe_salcomm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imsoe_salcomm_vw] TO [public]
GO
