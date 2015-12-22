SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                          CREATE PROC [dbo].[gl_gethomectry_sp]  @home_ctry_code varchar(3) OUTPUT 
AS BEGIN  SELECT @home_ctry_code = country_code FROM glco     SELECT @home_ctry_code = ISNULL(@home_ctry_code, '') 
 IF @home_ctry_code = '' RETURN 8110  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gethomectry_sp] TO [public]
GO
