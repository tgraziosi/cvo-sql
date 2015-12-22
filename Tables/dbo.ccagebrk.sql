CREATE TABLE [dbo].[ccagebrk]
(
[age_bracket1] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__19F8472A] DEFAULT ((0)),
[age_bracket2] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1AEC6B63] DEFAULT ((0)),
[age_bracket3] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1BE08F9C] DEFAULT ((0)),
[age_bracket4] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1CD4B3D5] DEFAULT ((0)),
[age_bracket5] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1DC8D80E] DEFAULT ((0)),
[age_bracket6] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1EBCFC47] DEFAULT ((0)),
[age_bracket7] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__1FB12080] DEFAULT ((0)),
[age_bracket8] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__20A544B9] DEFAULT ((0)),
[age_bracket9] [smallint] NOT NULL CONSTRAINT [DF__ccagebrk__age_br__219968F2] DEFAULT ((0)),
[user_id] [int] NOT NULL CONSTRAINT [DF__ccagebrk__user_i__228D8D2B] DEFAULT ((0))
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccagebrk] TO [public]
GO
GRANT SELECT ON  [dbo].[ccagebrk] TO [public]
GO
GRANT INSERT ON  [dbo].[ccagebrk] TO [public]
GO
GRANT DELETE ON  [dbo].[ccagebrk] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccagebrk] TO [public]
GO
