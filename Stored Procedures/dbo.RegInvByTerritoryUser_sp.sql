SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create proc [dbo].[RegInvByTerritoryUser_sp]
          @user varchar(1024),
          
       --@DateDocFrom Datetime,
       --@DateDocTo Datetime
                   
          @DateAppliedFrom Datetime,
          @DateAppliedTo Datetime
          
          
          --@DateShippedFrom Datetime,
          --@DateShippedTo Datetime
                   
          As
          Begin
          --Print @DateAppliedFrom
          --Print @DateAppliedTo
          
          --Declare @DateDocFromJ bigint
          --Declare @DateDocToJ bigint
            
          --select @DateDocFromJ = datediff(day,'1/1/1950',convert(datetime,
          --convert(varchar( 8), (year(@DateDocFrom) * 10000) + (month(@DateDocFrom) * 100) + day(@DateDocFrom)))  ) + 711858
          --select @DateDocToJ = datediff(day,'1/1/1950',convert(datetime,
          --convert(varchar( 8), (year(@DateDocTo) * 10000) + (month(@DateDocTo) * 100) + day(@DateDocTo)))  ) + 711858

	      Declare @DateAppliedFromJ int
          Declare @DateAppliedToJ int
          
          select @DateAppliedFromJ = datediff(day,'1/1/1950',convert(datetime,
          convert(varchar( 8), (year(@DateAppliedFrom) * 10000) + (month(@DateAppliedFrom) * 100) + day(@DateAppliedFrom)))  ) + 711858
          select @DateAppliedToJ = datediff(day,'1/1/1950',convert(datetime,
          convert(varchar( 8), (year(@DateAppliedTo) * 10000) + (month(@DateAppliedTo) * 100) + day(@DateAppliedTo)))  ) + 711858
          Print @DateAppliedFromJ
          Print @DateAppliedToJ
          
       --   Declare @DateShippedFromJ bigint
       --   Declare @DateShippedToJ bigint
          
       --   select @DateShippedFromJ = datediff(day,'1/1/1950',convert(datetime,
       --   convert(varchar( 8), (year(@DateShippedFrom) * 10000) + (month(@DateShippedFrom) * 100) + day(@DateShippedFrom)))  ) + 711858
       --   select @DateShippedToJ = datediff(day,'1/1/1950',convert(datetime,
       --   convert(varchar( 8), (year(@DateShippedTo) * 10000) + (month(@DateShippedTo) * 100) + day(@DateShippedTo)))  ) + 711858
          
          Declare @TodayDateJ int
          
          select @TodayDateJ = datediff(day,'1/1/1950',convert(datetime,
          convert(varchar( 8), (year(GETDATE()) * 10000) + (month(GETDATE()) * 100) + day(GETDATE())))  ) + 711858
          
                  
          select ADDRESS_NAME,CUSTOMER_CODE,State,ship_to_state,INVCRM,DOC_CTRL_NUM,TRX_CTRL_NUM,ORG_ID,PAST_DUE_STATUS
          ,SETTLED_STATUS,HOLD_FLAG,POSTED_FLAG,NAT_CUR_CODE,amt_gross,amt_discount,AMT_NET,amt_freight
	      ,amt_tax,AMT_PAID_TO_DATE,UNPAID_BALANCE,AMT_PAST_DUE,RECURRING_FLAG,
	     -- convert(varchar,dateadd(d,DATE_DOC-711858,'1/1/1950'),101) AS DATE_DOC,
	      DATE_DOC = 
	              CASE 
	                WHEN DATE_DOC=0 THEN convert(varchar, 0, 101)
	                   WHEN DATE_DOC=NULL THEN convert(varchar,null,101)
	                ELSE Convert(varchar,dateadd(d,DATE_DOC-711858,'1/1/1950'),101)
	               END,          
	     -- convert(varchar,dateadd(d,DATE_SHIPPED-711858,'1/1/1950'),101) AS DATE_SHIPPED, 
	      DATE_SHIPPED = 
	              CASE 
	                WHEN DATE_SHIPPED=0 THEN convert(varchar, 0, 101)
	                   WHEN DATE_SHIPPED=NULL THEN convert(varchar,null,101)
	                ELSE Convert(varchar,dateadd(d,DATE_SHIPPED-711858,'1/1/1950'),101)
	               END,
	      --convert(varchar,dateadd(d,DATE_APPLIED-711858,'1/1/1950'),101) AS DATE_APPLIED,
	      DATE_APPLIED = 
	              CASE 
	                WHEN DATE_APPLIED=0 THEN convert(varchar, 0, 101)
	                   WHEN DATE_APPLIED=NULL THEN convert(varchar,null,101)
	                ELSE Convert(varchar,dateadd(d,DATE_APPLIED-711858,'1/1/1950'),101)
	               END,
	      DATE_DUE = 
	              CASE 
	                WHEN DATE_DUE=0 THEN convert(varchar, 0, 101)
	                   WHEN DATE_DUE=NULL THEN convert(varchar,null,101)
	                ELSE Convert(varchar,dateadd(d,DATE_DUE-711858,'1/1/1950'),101)
	               END,          
	     -- convert(varchar,dateadd(d,DATE_SHIPPED-711858,'1/1/1950'),101) AS DATE_SHIPPED,
	      LAST_PAYMENT_DATE = 
	               CASE 
	                WHEN LAST_PAYMENT_DATE=0 THEN convert(varchar,0, 101)
	                WHEN LAST_PAYMENT_DATE=NULL THEN convert(varchar,null,101)
	                ELSE convert(varchar,dateadd(d,LAST_PAYMENT_DATE-711858,'1/1/1950'),101)
	              END,
	      CUST_PO_NUM,ORDER_CTRL_NUM,GL_TRX_ID,salesperson_code,ir.territory_code,order_type
          
          FROM
          CVO_InvReg_vw ir INNER JOIN f_get_terr_for_username(@user) tu 
            on ir.territory_code = tu.territory_code
          Where (Date_Applied BETWEEN ISNULL(@DateAppliedFromJ,693596) AND ISNULL(@DateAppliedToJ,@TodayDateJ))
                                                        
          End
GO
