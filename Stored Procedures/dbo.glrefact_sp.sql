SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE PROCEDURE [dbo].[glrefact_sp]  
 @acct_code varchar(32),  
 @ref_code varchar(32),  
 @form_call smallint = -1  
AS  
DECLARE @ref_type varchar(8), @acct_mask  varchar(32),   
 @ref_flag smallint, @refcode_required smallint  
  
  
  
  
SELECT @ref_type = reference_type  
FROM glref  (NOLOCK)
WHERE reference_code = @ref_code  
  
  
  
  
IF EXISTS (   
 SELECT  a.account_mask  
    FROM glrefact a (NOLOCK) 
    WHERE @acct_code LIKE a.account_mask  
    AND reference_flag = 1 )  
BEGIN  
   
  
  
 IF ( @form_call = -1 )  
  SELECT 0, 'This account is marked exclude for this reference type'  
 RETURN 0  
END  
  
  
SELECT  @acct_mask = MIN( account_mask )  
FROM glrefact (NOLOCK) 
WHERE @acct_code LIKE account_mask  
AND reference_flag IN ( 2, 3 )  
  
  
  
  
IF @acct_mask IS NULL  
BEGIN  
 IF ( @form_call = -1 )  
  SELECT 2, 'Mask is null'  
 RETURN 2  
END  
  
IF EXISTS( SELECT account_mask  
  FROM glrefact (NOLOCK) 
  WHERE @acct_code LIKE account_mask  
  AND reference_flag = 3)  
BEGIN  
 SELECT @refcode_required = 1  
END  
  
  
  
IF @refcode_required = 1  AND  
 @ref_code IN (  
  SELECT reference_code             
  FROM glref r (NOLOCK),           
   glratyp t (NOLOCK),           
   glrefact a (NOLOCK)      
  WHERE r.reference_type = t.reference_type       
    AND a.reference_flag = 3       
    AND a.account_mask = t.account_mask      
    AND @acct_code LIKE t.account_mask)  
BEGIN  
 IF ( @form_call = -1 )  
  SELECT 1, 'Reference code required and OK'  
 RETURN  1  
END  
  
ELSE IF @refcode_required = 1  
BEGIN  
 IF ( @form_call = -1 )  
  SELECT 0, 'Validation of required type failed'  
    RETURN  0  
END  
  
  
  
  
IF @ref_code IN (  
 SELECT reference_code  
 FROM glref r (NOLOCK),   
  glratyp t (NOLOCK),           
  glrefact a (NOLOCK)     
 WHERE r.reference_type = t.reference_type       
   AND a.reference_flag = 2       
   AND a.account_mask = t.account_mask      
   AND @acct_code LIKE t.account_mask )   
BEGIN  
 IF ( @form_call = -1 )  
  SELECT 1, 'Reference code optional and OK'  
 RETURN 1  
END  
  
ELSE  
BEGIN  
 IF ( @form_call = -1 )  
  SELECT 0, 'Validation of optional type failed'  
 RETURN 0  
END  
  
  
/**/                                                
GO
GRANT EXECUTE ON  [dbo].[glrefact_sp] TO [public]
GO
