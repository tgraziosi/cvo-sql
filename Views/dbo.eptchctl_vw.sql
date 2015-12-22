SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[eptchctl_vw]
AS
SELECT batch_ctrl_num,batch_description,start_date, 
	start_time,completed_date,completed_time,control_number, 
	control_total,actual_number,actual_total,batch_type,document_name, 
	hold_flag,posted_flag,void_flag,selected_flag,number_held, 
	date_applied,date_posted,time_posted,start_user,completed_user, 
	posted_user,company_code,selected_user_id,process_group_num, 
	page_fill_1,page_fill_2,page_fill_3,page_fill_4,page_fill_5, 
	page_fill_6,page_fill_7,page_fill_8  
 
FROM batchctl 
WHERE void_flag = 0 and 
batch_ctrl_num  IN ( 
				SELECT DISTINCT batch_code 
				FROM epmchhdr 
				WHERE validated_flag = 1
				AND match_posted_flag = 0	--Rev 1.0
			 ) 
AND posted_flag = 0
AND completed_date > 0
AND batch_type = 4065
AND hold_flag = 0

GO
GRANT REFERENCES ON  [dbo].[eptchctl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[eptchctl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[eptchctl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[eptchctl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[eptchctl_vw] TO [public]
GO
