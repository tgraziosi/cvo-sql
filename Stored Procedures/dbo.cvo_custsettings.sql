SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_custsettings]  
AS  
  
  
update armaster_all  
   set ship_complete_flag=(CASE WHEN t1."STATUS"='INACTIVE' THEN 0 ELSE 1 END)  
  from armaster_all t2  
inner  
  join cvo_cust_inactive t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1.F1), 6))  
  
  
update armaster_all  
   set ship_complete_flag=(CASE WHEN t1."Ship Partial"='YES' THEN 2 ELSE 0 END)  
  from armaster_all t2  
inner  
  join cvo_cust_shipp t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1.F1), 6))  
  
  
update cvo_armaster_all  
   set consol_ship_flag=(CASE WHEN t1."PRINT CREDIT MEMOS"='YES' THEN 1 ELSE 0 END)  
  from cvo_armaster_all t2  
inner  
  join cvo_cust_printcm t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1.F1), 6))  
  
  
  
update cvo_armaster_all  
   set consol_ship_flag=(CASE WHEN t1."FLAG FOR CONSOLIDATION"='YES' THEN 1 ELSE 0 END)  
  from cvo_armaster_all t2  
inner  
  join cvo_cust_consship t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1.F1), 6))  
  
update cvo_armaster_all  
   set allow_substitutes= 1  
  
  
update cvo_armaster_all  
   set allow_substitutes= 0  
  from cvo_armaster_all t2  
inner  
  join cvo_cust_allowsubs t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1."ACCT #"), 6))  
  
  
update cvo_armaster_all  
   set add_cases= 'N'  
  from cvo_armaster_all t2  
inner  
  join cvo_cust_cases t1  
    on t2.customer_code = (RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, t1.F1), 6))  
  
--loop for customer types  
declare @customer_code nvarchar(15)  
  
--select * from cvo_cust_key  
  
                           
DECLARE shipto_cursor CURSOR FOR                                  
select F1 from cvo_cust_key                                  
                                  
OPEN shipto_cursor;                                  
                                  
                                  
                                  
FETCH NEXT FROM shipto_cursor                                  
INTO @customer_code;                                  
                                  
WHILE @@FETCH_STATUS = 0                                  
BEGIN                          
  
--(RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, @customer_code), 6))  
  
--select * from cvo_cust_designation_codes --5427  
  
INSERT INTO cvo_cust_designation_codes ( customer_code, code, description, date_reqd )   
VALUES ( RIGHT(REPLICATE('0', 10) + CONVERT(VARCHAR, @customer_code), 6), 'KEY', 'KEY ACCOUNT', 0 )  
  
                                          
  FETCH NEXT FROM shipto_cursor                                                          
   INTO @customer_code                                                         
END                                         
                                                          
CLOSE shipto_cursor;                                                          
DEALLOCATE shipto_cursor;   
--end loop  
  
  
drop table cvo_cust_inactive  
drop table cvo_cust_shipp  
drop table cvo_cust_printcm  
drop table cvo_cust_consship  
drop table cvo_cust_allowsubs  
drop table cvo_cust_cases  
drop table cvo_cust_key
GO
GRANT EXECUTE ON  [dbo].[cvo_custsettings] TO [public]
GO
