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

-- exec arcusssrs_sp 'cvoptical\bbassett'

CREATE proc [dbo].[arcusSSRS_sp] @user varchar(1024)
 as 
exec (" Select ar.*,convert(varchar,dateadd(d,ar.date_opened-711858,'1/1/1950'),101) as DateOpened
from arcus_vw ar (nolock) inner join f_get_terr_for_username('" + @user + "') tu 
		on ar.territory_code = tu.territory_code order by address_name" )

GO
