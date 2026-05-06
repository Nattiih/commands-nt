CREATE TABLE IF NOT EXISTS `nt_punishments` (
    `passport` INT(11) NOT NULL,
    `end_time` INT(11) NOT NULL,
    `applied_by` INT(11) DEFAULT NULL,
    `applied_at` INT(11) NOT NULL,
    PRIMARY KEY (`passport`),
    INDEX `idx_end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
