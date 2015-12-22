CREATE TABLE [dbo].[arnarel]
(
[timestamp] [timestamp] NOT NULL,
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[arnarel_del_trg] ON [dbo].[arnarel] FOR
Delete
As

/*
**	CVO audit Parent-Child relationship movement
**	Explorer view used to report on movement of customers from one buying group to another
*/
INSERT CVOarnarelAudit (parent, child, relation_code, movement_flag, audit_date, audit_datetime)
SELECT parent, child, relation_code, 0, DATEDIFF(dd, '1/1/1753', CONVERT(VARCHAR(10), GETDATE(),101)) + 639906, GETDATE()
FROM   deleted


Declare @last_code varchar(8), 
	@relation_code varchar(8),
	@parent varchar(8),
	@last_parent varchar(8),
	@top_of_tier_parent varchar(8),
	@child varchar(8),
	@last_child varchar(8),
	@rtn_status int


Select @relation_code = ' '
While 1 = 1 
Begin

 
	Set RowCount 1

	Select @last_code = @relation_code,
		@last_parent = " "

	Select @relation_code = null



	Select @relation_code = d.relation_code
	From deleted d,
		arrelcde b
	Where b.tiered_flag = 1
	And d.relation_code = b.relation_code
	And d.relation_code > @last_code


	If @relation_code is null
		Break

	Set RowCount 0

	Select @parent = ' '

	While 1 = 1
	Begin




		Select @last_parent = @parent,
			@top_of_tier_parent = null

		Select @parent = Null

		Select @parent = Min(parent)
		From deleted d
		Where d.relation_code = @relation_code
		And d.parent > @last_parent

		If @parent is Null
			Break


		Select @top_of_tier_parent = Null

		Select @top_of_tier_parent = parent
		From artierrl
		Where relation_code = @relation_code
		And rel_cust = @parent

		If @top_of_tier_parent is Null
			Select @top_of_tier_parent = @parent

		Exec arbldna_sp @relation_code, @top_of_tier_parent



		Select @child = ' '

		While 1 = 1
		Begin
			Select @last_child = @child

			Select @child = Null

			Select @child = Min(child)
			From deleted d
			Where d.relation_code = @relation_code
			And d.parent = @parent
			And child > @last_child

			If @child is null
				Break

			Exec arbldna_sp @relation_code, @child
		End
	End
End

Set RowCount 0


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[arnarel_ins_trg] ON [dbo].[arnarel] FOR
INSERT
AS

/*
**	CVO audit Parent-Child relationship movement
**	Explorer view used to report on movement of customers from one buying group to another
*/
INSERT CVOarnarelAudit (parent, child, relation_code, movement_flag, audit_date, audit_datetime)
SELECT parent, child, relation_code, 1, DATEDIFF(dd, '1/1/1753', CONVERT(VARCHAR(10), GETDATE(),101)) + 639906, GETDATE()
FROM   inserted


declare @last_code varchar(8), 
	@relation_code varchar(8),
	@parent varchar(8),
	@last_parent varchar(8),
	@top_of_tier_parent varchar(8),
	@child varchar(8),
	@rtn_status int

SELECT @relation_code = ' ',
	@parent = ' '



While 1 = 1 
Begin
	Set RowCount 1
	Select @last_code = @relation_code,
		@last_parent = " "

	Select @relation_code = null



	Select @relation_code = i.relation_code
	From inserted i,
		arrelcde b
	Where b.tiered_flag = 1
	And i.relation_code = b.relation_code
	And i.relation_code > @last_code

	If @relation_code is null
		Break

	Set RowCount 0


	Delete artierrl
	Where relation_code = @relation_code
	And parent in ( 
				Select child
				From inserted)

	While 1 = 1
	Begin


		Select @last_parent = @parent,
			@top_of_tier_parent = null

		Select @parent = Null

		Select @parent = Min(parent)
		From inserted i
		Where i.relation_code = @relation_code
		And i.parent > @last_parent

		If @parent is Null
			Break



		Select @child = @parent


		While 1 = 1
		Begin
			Select @top_of_tier_parent = Null
	
			Select @top_of_tier_parent = parent
			From arnarel
			Where child = @child
			And relation_code = @relation_code

			If @top_of_tier_parent is Null
				Break

			Select @child = @top_of_tier_parent

		End

		Select @top_of_tier_parent = @child


		Exec arbldna_sp @relation_code, @top_of_tier_parent

	End

End

Set RowCount 0


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create Trigger [dbo].[arnarel_upd_trg] ON [dbo].[arnarel] FOR
Update
As

Declare @last_code varchar(8), 
	@relation_code varchar(8),
	@parent varchar(8),
	@last_parent varchar(8),
	@top_of_tier_parent varchar(8),
	@child varchar(8),
	@last_child varchar(8),
	@rtn_status int

Select @relation_code = ' '
While 1 = 1 
Begin
	Set RowCount 1

	Select @last_code = @relation_code,
		@last_parent = " "

	Select @relation_code = null



	Select @relation_code = d.relation_code
	From deleted d,
		arrelcde b
	Where b.tiered_flag = 1
	And d.relation_code = b.relation_code
	And d.relation_code > @last_code

	If @relation_code is null
		Break

	Set RowCount 0

	Select @parent = ' '

	While 1 = 1
	Begin


		Select @last_parent = @parent,
			@top_of_tier_parent = null

		Select @parent = Null

		Select @parent = Min(parent)
		From deleted d
		Where d.relation_code = @relation_code
		And d.parent > @last_parent

		If @parent is Null
			Break


		Select @top_of_tier_parent = Null

		Select @top_of_tier_parent = parent
		From artierrl
		Where relation_code = @relation_code
		And rel_cust = @parent

		If @top_of_tier_parent is Null
			Select @top_of_tier_parent = @parent

		Exec arbldna_sp @relation_code, @top_of_tier_parent



		Select @child = ' '

		While 1 = 1
		Begin
			Select @last_child = @child

			Select @child = Null

			Select @child = Min(child)
			From deleted d
			Where d.relation_code = @relation_code
			And d.parent = @parent
			And child > @last_child

			If @child is null
				Break



			Exec arbldna_sp @relation_code, @child
		End
		
	End
End

Set RowCount 0

Select @relation_code = ' ',
	@parent = ' '

While 1 = 1 
Begin

	Set RowCount 1

	Select @last_code = @relation_code,
		@last_parent = " "

	Select @relation_code = null



	Select @relation_code = i.relation_code
	From inserted i,
		arrelcde b
	Where b.tiered_flag = 1
	And i.relation_code = b.relation_code
	And i.relation_code > @last_code

	If @relation_code is null
		Break

	Set RowCount 0


	Delete artierrl
	Where relation_code = @relation_code
	And parent in ( 
				Select child
				From inserted)

	While 1 = 1
	Begin


		Select @last_parent = @parent,
			@top_of_tier_parent = null

		Select @parent = Null

		Select @parent = Min(parent)
		From inserted i
		Where i.relation_code = @relation_code
		And i.parent > @last_parent

		If @parent is Null
			Break



		Select @child = @parent

		While 1 = 1
		Begin
			Select @top_of_tier_parent = Null
	
			Select @top_of_tier_parent = parent
			From arnarel
			Where child = @child
			And relation_code = @relation_code

			If @top_of_tier_parent is Null
				Break

			Select @child = @top_of_tier_parent

		End

		Select @top_of_tier_parent = @child



		Exec arbldna_sp @relation_code, @top_of_tier_parent
	End
End

Set RowCount 0

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CVO_PARENT]

ON [dbo].[arnarel]

FOR INSERT

AS

BEGIN

	DECLARE @parent as varchar(20)
	DECLARE @child  as varchar(20)

	DECLARE cur CURSOR FOR
	SELECT parent,child  FROM INSERTED

	OPEN cur

	fetch next FROM cur
	INTO @parent, @child

	WHILE @@fetch_status = 0
	BEGIN
	
		  UPDATE arcust SET price_code = (SELECT price_code FROM arcust WHERE customer_code = @parent) 
		  Where customer_code = @child--child 

		fetch next from cur 
		into @parent, @child
	end
	
	close cur
	deallocate cur


END
GO
CREATE UNIQUE CLUSTERED INDEX [arnarel_ind_0] ON [dbo].[arnarel] ([relation_code], [parent], [child]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arnarel] TO [public]
GO
GRANT SELECT ON  [dbo].[arnarel] TO [public]
GO
GRANT INSERT ON  [dbo].[arnarel] TO [public]
GO
GRANT DELETE ON  [dbo].[arnarel] TO [public]
GO
GRANT UPDATE ON  [dbo].[arnarel] TO [public]
GO
