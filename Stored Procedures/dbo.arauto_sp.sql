SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arauto.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROC [dbo].[arauto_sp] @mask_in varchar(16),
 @temp_mask_in varchar(16)
AS

DECLARE 
 @error_flag smallint,
 @mi_prefix varchar(16),
 @temp_prefix varchar(16),
 @mi_suffix_type varchar(1),
 @temp_suffix_type varchar(1),
 @mi_len int,
 @temp_msk_len int,
 @mi_end_pos int,
 @temp_end_pos int,
 @char_holder varchar(16),
 @float_holder float,
 @int_holder int



 
 
 
 SELECT @mi_end_pos = CHARINDEX( "#", @mask_in )
 IF @mi_end_pos = 0 
 SELECT @mi_end_pos = CHARINDEX( "0", @mask_in )
 ELSE
 SELECT @mi_suffix_type = "#"
 SELECT @mi_len = DATALENGTH( RTRIM( @mask_in ) ) 
 SELECT @mi_prefix = SUBSTRING( @mask_in, 1, ( @mi_end_pos - 1 ) )
 
 
 
 
 SELECT @char_holder = @temp_mask_in
 SELECT @temp_end_pos = CHARINDEX( "#", @char_holder )
 IF @temp_end_pos = 0 
 SELECT @temp_end_pos = CHARINDEX( "0", @char_holder )
 ELSE
 SELECT @temp_suffix_type = "#"
 SELECT @temp_msk_len = DATALENGTH( RTRIM( @char_holder ) ) 
 SELECT @temp_prefix = SUBSTRING( @char_holder, 1, ( @temp_end_pos - 1 ) )
 
 
 
 
 
 
 
 
 SELECT @error_flag = 0
 IF @mi_prefix = @temp_prefix
 BEGIN
 IF @mi_len = @temp_msk_len
 SELECT @error_flag = 1
 ELSE
 BEGIN
 IF @temp_suffix_type = "#"
 BEGIN
 IF @mi_suffix_type = "#"
 SELECT @error_flag = 1
 ELSE
 IF @temp_msk_len > @mi_len 
 SELECT @error_flag = 1
 END
 IF @mi_suffix_type = "#"
 BEGIN
 IF @mi_len > @temp_msk_len
 SELECT @error_flag = 1
 END
 END
 END
SELECT @error_flag


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arauto_sp] TO [public]
GO
