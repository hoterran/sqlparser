select  a from b;
SELECT wp_posts.* FROM wp_posts WHERE ?=? AND wp_posts.ID IN (?,?,?,?,?,?,?) AND wp_posts.post_type = ? AND (wp_posts.        post_status = ?) ORDER BY wp_posts.menu_order ASC;
