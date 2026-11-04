extends RefCounted
## Convex silhouettes measured from the opaque armor in the current two atlases.
## Coordinates stay in atlas-cell pixels; visuals and physics apply the same transform.
const ATLANT := [
 [Vector2(91,124),Vector2(105,84),Vector2(190,20),Vector2(214,20),Vector2(326,68),Vector2(376,164),Vector2(374,188),Vector2(336,372),Vector2(316,432),Vector2(157,420),Vector2(138,388),Vector2(93,168)],
 [Vector2(120,240),Vector2(135,152),Vector2(169,88),Vector2(223,16),Vector2(237,20),Vector2(337,80),Vector2(350,116),Vector2(353,204),Vector2(252,420),Vector2(210,420),Vector2(177,412),Vector2(160,372)],
 [Vector2(137,104),Vector2(184,20),Vector2(233,12),Vector2(272,36),Vector2(292,156),Vector2(299,372),Vector2(294,400),Vector2(266,432),Vector2(208,432),Vector2(187,424),Vector2(176,396),Vector2(137,156)],
 [Vector2(105,220),Vector2(145,108),Vector2(156,104),Vector2(221,104),Vector2(264,116),Vector2(297,132),Vector2(337,164),Vector2(338,236),Vector2(330,316),Vector2(318,316),Vector2(125,284),Vector2(108,252)],
 [Vector2(144,52),Vector2(187,16),Vector2(256,16),Vector2(291,60),Vector2(313,148),Vector2(308,300),Vector2(286,396),Vector2(245,428),Vector2(195,428),Vector2(171,408),Vector2(145,276),Vector2(126,108)],
 [Vector2(131,184),Vector2(165,28),Vector2(175,16),Vector2(244,16),Vector2(258,24),Vector2(278,56),Vector2(292,116),Vector2(264,340),Vector2(244,428),Vector2(191,428),Vector2(174,416),Vector2(154,364)],
 [Vector2(66,352),Vector2(67,336),Vector2(93,188),Vector2(222,188),Vector2(361,320),Vector2(375,348),Vector2(375,356),Vector2(372,360),Vector2(132,360),Vector2(69,356)],
]
const KLYK := [
 [Vector2(56,108),Vector2(133,40),Vector2(184,16),Vector2(235,16),Vector2(307,52),Vector2(369,124),Vector2(385,208),Vector2(388,392),Vector2(381,420),Vector2(170,424),Vector2(56,200),Vector2(46,128)],
 [Vector2(56,220),Vector2(111,172),Vector2(201,112),Vector2(288,80),Vector2(349,72),Vector2(404,108),Vector2(419,136),Vector2(409,188),Vector2(374,240),Vector2(299,308),Vector2(55,384),Vector2(25,328)],
 [Vector2(146,80),Vector2(206,36),Vector2(254,16),Vector2(315,28),Vector2(338,88),Vector2(345,144),Vector2(298,356),Vector2(271,400),Vector2(235,424),Vector2(183,424),Vector2(171,408),Vector2(126,144)],
 [Vector2(95,352),Vector2(105,324),Vector2(261,48),Vector2(283,20),Vector2(322,8),Vector2(352,44),Vector2(353,76),Vector2(286,276),Vector2(229,428),Vector2(165,428),Vector2(106,392),Vector2(96,368)],
 [Vector2(79,336),Vector2(99,184),Vector2(149,108),Vector2(196,60),Vector2(248,28),Vector2(355,20),Vector2(378,60),Vector2(370,148),Vector2(238,400),Vector2(209,424),Vector2(139,424),Vector2(93,380)],
 [Vector2(128,400),Vector2(135,68),Vector2(140,48),Vector2(164,12),Vector2(237,12),Vector2(262,36),Vector2(337,184),Vector2(344,216),Vector2(330,260),Vector2(231,424),Vector2(148,428),Vector2(131,424)],
 [Vector2(36,308),Vector2(45,288),Vector2(65,268),Vector2(77,260),Vector2(317,116),Vector2(402,116),Vector2(417,208),Vector2(417,228),Vector2(387,316),Vector2(379,328),Vector2(165,368),Vector2(62,352)],
]
