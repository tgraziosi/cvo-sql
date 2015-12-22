SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/



CREATE VIEW [dbo].[gddispatch_vw]
AS
SELECT     R.location, R.resource_code, R.resource_name, SP.prod_no, SP.prod_ext, SP.source_flag, SPP.part_no, SPP.uom_qty * SP.process_unit AS uom_qty, 
                      SPP.uom, SO.operation_step, SO.work_datetime, SO.done_datetime, SO.operation_status, dbo.sched_model.sched_name
FROM         dbo.resource R INNER JOIN
                      dbo.sched_resource SR ON R.resource_id = SR.resource_id INNER JOIN
                      dbo.sched_operation_resource SOR ON SR.sched_resource_id = SOR.sched_resource_id INNER JOIN
                      dbo.sched_operation SO ON SOR.sched_operation_id = SO.sched_operation_id INNER JOIN
                      dbo.sched_process SP ON SO.sched_process_id = SP.sched_process_id LEFT OUTER JOIN
                      dbo.sched_model ON SP.sched_id = dbo.sched_model.sched_id LEFT OUTER JOIN
                      dbo.sched_process_product SPP ON SP.sched_process_id = SPP.sched_process_id
WHERE     (SPP.usage_flag = 'P') AND (DATEDIFF(mi, SO.work_datetime, SO.done_datetime) > 0)  


/**/
GO
GRANT REFERENCES ON  [dbo].[gddispatch_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gddispatch_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gddispatch_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gddispatch_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gddispatch_vw] TO [public]
GO
