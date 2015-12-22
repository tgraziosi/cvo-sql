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
CREATE PROCEDURE [dbo].[apstlrates_sp] @payments_date int,  @nat_cur_code varchar(8),  @v_currency varchar(8), 
 @rate_type varchar(8),  @rate float = NULL OUTPUT AS BEGIN  DECLARE  @error int, 
 @divide_flag smallint    EXEC @error = CVO_Control..mccurate_sp  @payments_date,  @nat_cur_code, 
 @v_currency,  @rate_type,  @rate OUTPUT,  0,  @divide_flag OUTPUT    IF ( @error != 0 ) 
 SELECT @rate = 0 SELECT @error , @nat_cur_code, @v_currency, @rate_type, @rate END 


 /**/
GO
GRANT EXECUTE ON  [dbo].[apstlrates_sp] TO [public]
GO
