SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_POLoad]              
AS              
              
--select * from cvo_temppo_pre              
              
declare @PONumber int              
              
DECLARE po_cursor CURSOR FOR                                                  
select distinct PONumber from cvo_temppo_pre                                                  
                                                  
OPEN po_cursor;                                                  
                  
                                                  
                                                  
                                                  
FETCH NEXT FROM po_cursor                                                  
INTO @PONumber                                                  
                                                  
WHILE @@FETCH_STATUS = 0                                                  
BEGIN                  
              
              
              
------------------              
select *              
INTO cvo_temppo              
FROM cvo_temppo_pre              
where PONumber=@PONumber              
              
exec CVO_PurchaseOrder @PONumber              
              
            
update purchase set proc_po_no = NULL, internal_po_ind=0 where po_no=@PONumber   --fzambada            
update pur_list set type='P',orig_part_type='P' where po_no=@PONumber      
update releases set part_type='P' where po_no=@PONumber   
            


drop table cvo_temppo              
              
--select @PONumber              
              
------------------              
              
              
  FETCH NEXT FROM po_cursor                                                  
   INTO @PONumber                                                  
END                                                  
                        
--fix extended amt  
exec CVO_POAMT  
--end fix extended amt                            
CLOSE po_cursor;                                                  
DEALLOCATE po_cursor; 
GO
GRANT EXECUTE ON  [dbo].[CVO_POLoad] TO [public]
GO
