SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_date_range_vw] AS

-- select * from cvo_date_range_vw

select 
	Convert(varchar(100),'Year To Date') as [Period]
	,convert(datetime,'1/1/' + cast(year(getdate()) as varchar(4))) as BeginDate
	,convert(datetime,DATEDIFF(dd,0,GETDATE()))-1 as EndDate
union all
select 
	Convert(varchar(100),'Last Year to Date') as [Period]
	,convert(datetime,'1/1/' + cast(year(getdate())-1 as varchar(4))) as BeginDate
	,dateadd(yy,-1,convert(datetime,datediff(dd,0,getdate())))-1 as EndDate
UNION ALL
SELECT
	CONVERT(varchar(100),'Rolling 12 TY') as [Period]
	,convert(datetime,DATEDIFF(dd,0,DATEADD(YEAR,-1,GETDATE()))) as BeginDate
	,convert(datetime,datediff(dd,0,getdate()))-1 as EndDate
UNION ALL
SELECT
	CONVERT(varchar(100),'Rolling 12 LY') as [Period]
	,convert(datetime,DATEDIFF(dd,0,DATEADD(YEAR,-2,GETDATE()))) as BeginDate
	,convert(datetime,DATEDIFF(dd,0,DATEADD(YEAR,-1,GETDATE())))-1 as EndDate
UNION all
select 
	Convert(varchar(100),'Today') as [Period]
	,convert(datetime,datediff(dd,0,getdate())) as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Yesterday') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-1 as BeginDate
	,convert(datetime,datediff(dd,0,getdate()))-1 as EndDate
UNION ALL
select 
	Convert(varchar(100),'This Week') as [Period]
	,Convert(varchar, DateAdd(dd, 1-(DatePart(dw,GETDATE()) - 1),GETDATE()), 101) Begindate
	,Convert(varchar, DateAdd(dd, (9 - DatePart(dw, GETDATE())),GETDATE()), 101) EndDate

union all
-- the Fiscal year is assumed to start on October 1.  You can change the constant to another fiscal year.
--select 
--	Convert(varchar(100),'Fiscal Year To Date') as [Period]
--	,convert(datetime,'1/1/' + cast(year(getdate()) as varchar(4))) as BeginDate
--	,convert(datetime,datediff(dd,0,getdate())) as EndDate
--union all
select 
	Convert(varchar(100),'Month To Date') as [Period]
	,convert(datetime,DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),-0)) as BeginDate
	,convert(datetime,datediff(dd,0,getdate())-1) as EndDate
union all
select 
	Convert(varchar(100),'Last Month') as [Period]
	,convert(datetime,DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-1,GETDATE())),0)) as BeginDate
	,convert(datetime,DATEADD(MONTH,DATEDIFF(month,0,GETDATE()),-0))-1 AS EndDate
	-- SELECT * FROM dbo.cvo_date_range_vw WHERE period = 'last month'
union all
select 
	Convert(varchar(100),'Last Month to Date') as [Period]
	,convert(datetime,DATEADD(MONTH,DATEDIFF(MONTH,0,DATEADD(MONTH,-1,GETDATE())),0)) as BeginDate
	,CONVERT(DATETIME,DATEADD(MONTH,-1,DATEDIFF(DAY,0,GETDATE())))-1 AS EndDate
-- SELECT * FROM dbo.cvo_date_range_vw WHERE period = 'last month to date'
union all
select 
	Convert(varchar(100),'Last Year') as [Period]
	,convert(datetime,'1/1/' + cast(year(getdate())-1 as varchar(4))) as BeginDate
	,convert(datetime,'1/1/' + cast(year(getdate()) as varchar(4)))-1 as EndDate

union all
select 
	Convert(varchar(100),'Last 7 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-7 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 14 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-14 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 21 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-21 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 28 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-28 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 30 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-30 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 60 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-60 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
union all
select 
	Convert(varchar(100),'Last 90 days') as [Period]
	,convert(datetime,datediff(dd,0,getdate()))-90 as BeginDate
	,convert(datetime,datediff(dd,0,getdate())) as EndDate
--union all
--select 
--	Convert(varchar(100),'This Calendar Quarter') as [Period]
--	,DATEADD(qq, DATEDIFF(q,0,GETDATE()),0) as BeginDate
--	,DATEADD(qq, DATEDIFF(q,0,GETDATE())+1,0)-1 as EndDate
--union all
--select 
--	Convert(varchar(100),'This Calendar Quarter to Date') as [Period]
--	,DATEADD(qq, DATEDIFF(q,0,GETDATE()),0) as BeginDate
--	,convert(datetime,datediff(dd,0,getdate())) as EndDate
--union all
--select 
--	Convert(varchar(100),'Last Calendar Quarter') as [Period]
--	,DATEADD(qq, DATEDIFF(q,2,GETDATE())-1,0) as BeginDate
--	,DATEADD(qq, DATEDIFF(q,2,GETDATE()),0)-1 as EndDate
--union all
--select 
--	Convert(varchar(100),'Last Calendar Quarter to Date') as [Period]
--	,DATEADD(qq, DATEDIFF(q,0,GETDATE())-1,0) as BeginDate
--	,DATEADD(QQ,-1,convert(datetime,datediff(dd,0,getdate()))) as EndDate
--union all
--select 
--	Convert(varchar(100),'Last Year Calendar Quarter') as [Period]
--	,DATEADD(yyyy,-1,DATEADD(qq, DATEDIFF(q,2,GETDATE()),0)) as BeginDate
--	,DATEADD(yyyy,-1,DATEADD(qq, DATEDIFF(q,2,GETDATE())+1,0)-1) as EndDateunion
--union all
--select 
--	Convert(varchar(100),'Last Year Calendar Quarter to Date') as [Period]
--	,DATEADD(yyyy,-1,DATEADD(qq, DATEDIFF(q,2,GETDATE()),0)) as BeginDate
--	,DATEADD(yyyy,-1,convert(datetime,datediff(dd,0,getdate()))) as EndDate
--union all
--select 
--	Convert(varchar(100),'Next Year') as [Period]
--	,Convert(datetime,'1/1/' + cast(YEAR(GETDATE())+1 as varchar(4))) as BeginDate
--	,Convert(datetime,'12/31/' + cast(YEAR(GETDATE())+1 as varchar(4)))  as EndDate
--union all
--select 
--	Convert(varchar(100),'Next Year to Date') as [Period]
--	,Convert(datetime,'1/1/' + cast(YEAR(GETDATE())+1 as varchar(4))) as BeginDate
--	,Convert(datetime,cast(MONTH(GETDATE()) as varchar(2)) + '/' + cast(DAY(GETDATE()) as varchar(2)) + '/' + cast(YEAR(GETDATE())+1 as varchar(4)))  as EndDate


GO
