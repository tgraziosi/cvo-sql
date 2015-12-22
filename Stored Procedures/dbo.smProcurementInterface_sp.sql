SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                













                                                

CREATE PROC [dbo].[smProcurementInterface_sp]
	@flag smallint  
AS    


  	IF (@flag=0) 
	BEGIN 
		/*--- 73 INTEGRATION (NOT USED ANYMORE) ---*/
		IF EXISTS (select * from sysobjects where name = 'glchart_upd_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glchart_del_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glchart_ins_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_ins_trg 
		
		IF EXISTS (select * from sysobjects where name = 'glratyp_upd_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glratyp_del_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glratyp_ins_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_ins_trg 
		
		IF EXISTS (select * from sysobjects where name = 'glref_upd_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glref_del_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glref_ins_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_ins_trg 		

		IF EXISTS (select * from sysobjects where name = 'glrefact_upd_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glrefact_del_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glrefact_ins_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_ins_trg 		
		
		/*--- 74 INTEGRATION ---*/
		ALTER TABLE glchart DISABLE TRIGGER glchart_integ_del_trg
		ALTER TABLE glchart DISABLE TRIGGER glchart_integ_ins_trg
		ALTER TABLE glchart DISABLE TRIGGER glchart_integ_upd_trg
		
		ALTER TABLE glchart DISABLE TRIGGER glchart_integration_ins_trg
		ALTER TABLE glchart DISABLE TRIGGER glchart_integration_del_trg
		ALTER TABLE glchart DISABLE TRIGGER glchart_integration_upd_trg

		ALTER TABLE glratyp DISABLE TRIGGER glratyp_integ_del_trg
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_integ_ins_trg
		
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_integration_del_trg
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_integration_ins_trg
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_integration_upd_trg

		ALTER TABLE glref DISABLE TRIGGER glref_integ_upd_trg
		ALTER TABLE glref DISABLE TRIGGER glref_integ_ins_trg
		
		ALTER TABLE glref DISABLE TRIGGER glref_integration_del_trg
		ALTER TABLE glref DISABLE TRIGGER glref_integration_ins_trg
		ALTER TABLE glref DISABLE TRIGGER glref_integration_upd_trg

		ALTER TABLE glrefact DISABLE TRIGGER glrefact_integ_upd_trg
		
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_integration_del_trg
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_integration_ins_trg
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_integration_upd_trg

		/*--------------------------*/
		ALTER TABLE apmaster_all DISABLE TRIGGER apmaster_all_integration_del_trg
		ALTER TABLE apmaster_all DISABLE TRIGGER apmaster_all_integration_ins_trg
		ALTER TABLE apmaster_all DISABLE TRIGGER apmaster_all_integration_upd_trg
		ALTER TABLE inv_master DISABLE TRIGGER inv_master_integration_del_trg
		ALTER TABLE inv_master DISABLE TRIGGER inv_master_integration_ins_trg
		ALTER TABLE inv_master DISABLE TRIGGER inv_master_integration_upd_trg
		ALTER TABLE locations_all DISABLE TRIGGER locations_integration_del_trg
		ALTER TABLE locations_all DISABLE TRIGGER locations_integration_ins_trg
		ALTER TABLE locations_all DISABLE TRIGGER locations_integration_upd_trg
	END


















	
	IF (@flag<>0) 
	BEGIN
		/*--- 73 INTEGRATION (NOT USED ANYMORE) ---*/
		IF EXISTS (select * from sysobjects where name = 'glchart_upd_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glchart_del_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glchart_ins_trg')
		ALTER TABLE glchart DISABLE TRIGGER glchart_ins_trg 
		
		IF EXISTS (select * from sysobjects where name = 'glratyp_upd_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glratyp_del_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glratyp_ins_trg')
		ALTER TABLE glratyp DISABLE TRIGGER glratyp_ins_trg 
		
		IF EXISTS (select * from sysobjects where name = 'glref_upd_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glref_del_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glref_ins_trg')
		ALTER TABLE glref DISABLE TRIGGER glref_ins_trg 		

		IF EXISTS (select * from sysobjects where name = 'glrefact_upd_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_upd_trg 
		IF EXISTS (select * from sysobjects where name = 'glrefact_del_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_del_trg 
		IF EXISTS (select * from sysobjects where name = 'glrefact_ins_trg')
		ALTER TABLE glrefact DISABLE TRIGGER glrefact_ins_trg 			
		
		/*--- 74 INTEGRATION ---*/
		ALTER TABLE glchart ENABLE TRIGGER glchart_integ_del_trg
		ALTER TABLE glchart ENABLE TRIGGER glchart_integ_ins_trg
		ALTER TABLE glchart ENABLE TRIGGER glchart_integ_upd_trg
		
		ALTER TABLE glchart ENABLE TRIGGER glchart_integration_ins_trg
		ALTER TABLE glchart ENABLE TRIGGER glchart_integration_del_trg
		ALTER TABLE glchart ENABLE TRIGGER glchart_integration_upd_trg

		ALTER TABLE glratyp ENABLE TRIGGER glratyp_integ_del_trg
		ALTER TABLE glratyp ENABLE TRIGGER glratyp_integ_ins_trg
		
		ALTER TABLE glratyp ENABLE TRIGGER glratyp_integration_del_trg
		ALTER TABLE glratyp ENABLE TRIGGER glratyp_integration_ins_trg
		ALTER TABLE glratyp ENABLE TRIGGER glratyp_integration_upd_trg

		ALTER TABLE glref ENABLE TRIGGER glref_integ_upd_trg
		ALTER TABLE glref ENABLE TRIGGER glref_integ_ins_trg
		
		ALTER TABLE glref ENABLE TRIGGER glref_integration_del_trg
		ALTER TABLE glref ENABLE TRIGGER glref_integration_ins_trg
		ALTER TABLE glref ENABLE TRIGGER glref_integration_upd_trg

		ALTER TABLE glrefact ENABLE TRIGGER glrefact_integ_upd_trg
		
		ALTER TABLE glrefact ENABLE TRIGGER glrefact_integration_del_trg
		ALTER TABLE glrefact ENABLE TRIGGER glrefact_integration_ins_trg
		ALTER TABLE glrefact ENABLE TRIGGER glrefact_integration_upd_trg

		/*--------------------------*/
		ALTER TABLE apmaster_all ENABLE TRIGGER apmaster_all_integration_del_trg
		ALTER TABLE apmaster_all ENABLE TRIGGER apmaster_all_integration_ins_trg
		ALTER TABLE apmaster_all ENABLE TRIGGER apmaster_all_integration_upd_trg
		ALTER TABLE inv_master ENABLE TRIGGER inv_master_integration_del_trg
		ALTER TABLE inv_master ENABLE TRIGGER inv_master_integration_ins_trg
		ALTER TABLE inv_master ENABLE TRIGGER inv_master_integration_upd_trg
		ALTER TABLE locations_all ENABLE TRIGGER locations_integration_del_trg
		ALTER TABLE locations_all ENABLE TRIGGER locations_integration_ins_trg
		ALTER TABLE locations_all ENABLE TRIGGER locations_integration_upd_trg	
	 	
    END 
GO
GRANT EXECUTE ON  [dbo].[smProcurementInterface_sp] TO [public]
GO
