SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apchktbl.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROC [dbo].[apchktbl_sp] @table_in varchar(8)
AS

DECLARE 
 @table_exists smallint

SELECT @table_exists = 0
IF EXISTS ( SELECT name FROM sysobjects WHERE name = @table_in )
 BEGIN
 SELECT @table_exists = 1
 END
SELECT @table_exists
GO
GRANT EXECUTE ON  [dbo].[apchktbl_sp] TO [public]
GO
