SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arcmpdat.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[arcmpdat_sp]	@form_entered_time datetime,
 @form_saved_time datetime,
 @cur_pid int

AS
 

 DECLARE @cdate datetime,
 @last_save_time datetime,
 @ediff int,
 @sdiff int,
 @mediff int,
 @msdiff int,
 @pid int


 SELECT @cdate = @form_entered_time

 SELECT 
 @pid = pid,
 @last_save_time = last_save_time
 FROM
 arconcry

 
 IF ( @cur_pid = @pid )
 BEGIN
 SELECT 0
 RETURN
 END

 SELECT @ediff = DATEDIFF(second, @last_save_time, @form_entered_time )
 SELECT @sdiff = DATEDIFF(second, @last_save_time, @form_saved_time )

 IF ( @ediff = 0 )
 SELECT @mediff = DATEDIFF(millisecond, @last_save_time, 
 @form_entered_time )
 IF ( @sdiff = 0 )
 SELECT @msdiff = DATEDIFF(millisecond, @last_save_time, 
 @form_saved_time )

 
 IF ( @form_entered_time > @form_saved_time )
 BEGIN
 SELECT -2
 RETURN
 END

 IF ( @ediff = 0 )
 SELECT @ediff = @mediff
 IF ( @sdiff = 0 )
 SELECT @sdiff = @msdiff

 IF ( @ediff < 0 AND @sdiff > 0 ) OR ( @ediff = 0 AND @sdiff = 0 ) OR
 ( @sdiff = 0 )
 SELECT -1
 ELSE
 SELECT 0

 RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcmpdat_sp] TO [public]
GO
