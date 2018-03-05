CREATE TABLE [dbo].[in_gltrxdet]
(
[timestamp] [timestamp] NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[trx_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_posted] [datetime] NOT NULL,
[company_id] [smallint] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[balance] [decimal] (20, 8) NOT NULL,
[nat_balance] [decimal] (20, 8) NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [decimal] (20, 8) NOT NULL,
[balance_oper] [decimal] (20, 8) NULL,
[rate_oper] [decimal] (20, 8) NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[apply_date] [datetime] NULL,
[crdb] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[acct_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_line] [int] NOT NULL CONSTRAINT [DF__in_gltrxd__tran___094B4767] DEFAULT ((0)),
[tran_qty] [decimal] (20, 8) NULL,
[tran_cost] [decimal] (20, 8) NULL,
[tran_date] [datetime] NULL CONSTRAINT [DF__in_gltrxd__tran___0A3F6BA0] DEFAULT (getdate()),
[line_descr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[controlling_organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t650delingltrxdet] ON [dbo].[in_gltrxdet]  FOR DELETE AS 
begin
return


if exists (select * from config where flag='TRIG_DEL_GLTRXDET' and value_str='DISABLE')
	return
else
   begin
     rollback tran
     exec adm_raiserror 73299 ,'You Can Not Delete A GL TRANSACTION!' 
     return
   end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t650insingltrxdet] ON [dbo].[in_gltrxdet]   FOR INSERT AS 


BEGIN
DECLARE @return int,@direction int
DECLARE @apply_date datetime, @xlp int, @date_applied int				-- mls 9/23/99 SCR 70 20886 start
DECLARE @prev_date_applied int, @msg varchar(255)

select @prev_date_applied = 0

select @xlp = isnull((select min(row_id) from inserted),null)

while @xlp is not null
begin
  select @apply_date = apply_date
    from in_gltrxdet where row_id = @xlp
  
  select @date_applied = datediff(day,'01/01/1900',@apply_date) + 693596

  if @prev_date_applied != @date_applied 
  begin
    select @prev_date_applied = @date_applied

    if not exists (select * from glprd (nolock) where @date_applied between period_start_date and period_end_date)
    begin
      select @msg = 'Invalid apply date: [' + convert(varchar(40),@apply_date,107)  	
      select @msg  = @msg + '] on transaction: [' + trx_type + ':' + convert(varchar(12),tran_no) + '-' + 
        convert(varchar(12),tran_ext) + ']'
      from in_gltrxdet where row_id = @xlp

      rollback tran
      exec adm_raiserror 990923, @msg
      return
    end
  end
select @xlp = isnull((select min(row_id) from inserted where row_id > @xlp),null)
end													-- mls 9/23/99 SCR 70 20886 end

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t650updingltrxdet] ON [dbo].[in_gltrxdet]  FOR UPDATE  AS 
BEGIN

if update(posted_flag) or update(date_posted) or update(sequence_id) and
 NOT ( UPDATE(part_no) OR UPDATE(location) OR UPDATE(seg1_code) or UPDATE(account_code) or
       UPDATE(seg2_code) or UPDATE(seg3_code) or UPDATE(seg4_code) or
       UPDATE(balance) or UPDATE(nat_balance) or UPDATE(nat_cur_code) or
       UPDATE(rate) or UPDATE(balance_oper) or UPDATE(rate_oper) or
       UPDATE(rate_type_home) or UPDATE(rate_type_oper) ) return


if exists (select * from config where flag='TRIG_UPD_INGLTRX' and value_str='DISABLE')
	return
else
	rollback tran
	exec adm_raiserror 93231, 'You Cannot Update GL Transaction Table!'
	return
END

GO
CREATE NONCLUSTERED INDEX [ingltrxdet_0] ON [dbo].[in_gltrxdet] ([posted_flag], [apply_date], [row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ingltrxdet_1] ON [dbo].[in_gltrxdet] ([row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ingltrxdet_2] ON [dbo].[in_gltrxdet] ([tran_id], [row_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ingltrxdet_m1] ON [dbo].[in_gltrxdet] ([trx_type], [tran_no], [tran_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[in_gltrxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[in_gltrxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[in_gltrxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[in_gltrxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[in_gltrxdet] TO [public]
GO
