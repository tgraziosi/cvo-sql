SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
exec cvo_araging_int_sp 0
REPLACES CVO_ARAGING_BG - DONT NEED THAT VERSION ANYMORE.  
*/
CREATE procedure [dbo].[cvo_araging_int_sp] @regen int 
as 

begin

   if @regen = 1 exec cvo_araging_ssrs_sp

set nocount on


--select * From arcust


Select  ar.CUST_CODE ,
        ar.[KEY] ,
        ar.attn_email ,
        ar.SLS ,
        ar.TERR ,
        ar.REGION ,
        ar.NAME ,
        ar.BG_CODE ,
        ar.BG_NAME ,
        ar.TMS ,
        ar.AVGDAYSLATE ,
        ar.BAL ,
        ar.FUT ,
        ar.CUR ,
        ar.AR30 ,
        ar.AR60 ,
        ar.AR90 ,
        ar.AR120 ,
        ar.AR150 ,
        ar.CREDIT_LIMIT ,
        ar.ONORDER ,
        ar.lpmtdt ,
        ar.AMOUNT ,
        ar.YTDCREDS ,
        ar.YTDSALES ,
        ar.LYRSALES ,
        ar.r12sales ,
        ar.HOLD ,
        ar.date_asof ,
        ar.date_type_string ,
        ar.date_type
, (AR30+AR60+AR90+AR120+AR150) AS TOTPD, Case 
When BAL < 1  Then 'LT1'
When (AR30+AR60+AR90+AR120+AR150) < 1 then 'LT1'
Else
'GT1'
End As CheckBal
,case
When [KEY] = 'Intl Retailer' And (AR90 >=1 OR AR120 >= 1 OR AR150 >= 1) Then 'I90'
Else
''
End As INTL90
,Case
When [key] <> 'Key Account' AND [key] <> 'Intl Retailer' And (AR60 >=1 OR AR90 >=1 OR AR120 >= 1 OR AR150 >= 1) Then 'NK60'
Else
''
End As NonKey60
,Case
When Hold = '' OR Hold is NULL Then ''
Else
'H'
End As IsHold
,Case
When BAL - Credit_Limit > 1000  and [key] <> 'Buying Group' Then 'OCL1K'
Else
''
End As OverCL
From dbo.SSRS_ARAging_Temp ar
ORDER BY bal desc

end

/*
=IIF(Fields!IsHold.Value = "H" OR (Fields!CheckBal.Value <> "LT1" 
AND (Fields!OverCL.Value = "OCL1K" OR Fields!NonKey60.Value = "NK60" 
OR Fields!INTL90.Value = "I90")) ,"Red",Nothing)

Red = on Acctg Hold (H) or 
	1) they are over credit limit by more than 1000
	2) they are not a key account and have a balance in over 60 days or more
	3) they are international and have a balance in over 90 days or more.
*/
GO
GRANT EXECUTE ON  [dbo].[cvo_araging_int_sp] TO [public]
GO
