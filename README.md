# 🍜 Danny's Diner — SQL Case Study

Analyzing a small restaurant's sales, menu, and loyalty-program data with SQL Server to understand customer behavior and help decide whether to expand the loyalty program.

---

## 📌 Project Overview

Danny's Diner is a small Japanese restaurant selling sushi, curry, and ramen. The owner has basic data but no idea how to use it. This project answers **10 business questions** and **2 bonus tasks** about visiting patterns, spending, favorite items, and loyalty-program points, using **Window Functions, CTEs, CASE WHEN, and Views**.

> Based on **Case Study #1** of the [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-1/).

## 🗂️ Dataset

Three tables in the `dannys_diner` schema:

| Table | Description |
|---|---|
| `sales` | Every purchase: `customer_id`, `order_date`, `product_id` |
| `menu` | Maps `product_id` to `product_name` and `price` |
| `members` | When each customer joined the loyalty program (`join_date`) |

**Menu**

| product_id | product_name | price |
|---|---|---|
| 1 | sushi | 10 |
| 2 | curry | 15 |
| 3 | ramen | 12 |

**Members**

| customer_id | join_date |
|---|---|
| A | 2021-01-07 |
| B | 2021-01-09 |

Customer **C** appears in `sales` but is **not** a loyalty member.

---

## 🧠 Questions & Solutions

| # | Business Question | Techniques |
|---|---|---|
| 1 | Total amount each customer spent | `SUM()`, `GROUP BY`, `JOIN` |
| 2 | Number of days each customer visited | `COUNT(DISTINCT)` |
| 3 | First item(s) each customer purchased | `DENSE_RANK()`, CTE, `STRING_AGG()` |
| 4 | Most purchased item overall | `COUNT()`, `TOP 1` |
| 5 | Most popular item for each customer | `RANK()`, `PARTITION BY`, CTE |
| 6 | First item purchased after becoming a member | `RANK()`, CTE, `STRING_AGG()` |
| 7 | Item purchased just before becoming a member | `RANK() ... DESC`, CTE |
| 8 | Total items and amount spent before membership | `JOIN`, `COUNT()`, `SUM()` |
| 9 | Points per customer (sushi = 2x) | `CASE WHEN`, `SUM()` |
| 10 | Points for A and B by end of January (2x on everything in the first week after joining) | `CASE WHEN`, `DATEADD()`, `BETWEEN` |
| Bonus 1 | Purchase history with membership status | `VIEW`, `LEFT JOIN`, `CASE WHEN` |
| Bonus 2 | Rank member purchases, `NULL` for non-members | `DENSE_RANK()`, `CASE WHEN` |

### Example: Points by End of January

```sql
SELECT 
    mb.customer_id,
    SUM(CASE
            WHEN s.order_date BETWEEN mb.join_date AND DATEADD(DAY, 6, mb.join_date) THEN m.price * 20
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END) AS points
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
INNER JOIN dannys_diner.members AS mb ON s.customer_id = mb.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY mb.customer_id;
```

---

## 📊 Key Results

| Question | A | B | C |
|---|---|---|---|
| Total spent | $76 | $74 | $36 |
| Days visited | 4 | 6 | 2 |
| First item(s) | curry, sushi | curry | ramen |
| Favorite item | ramen | curry, sushi, ramen (tie) | ramen |
| First item after joining | curry | sushi | not a member |
| Last item before joining | curry, sushi | sushi | not a member |
| Items / spent before joining | 2 / $25 | 3 / $40 | not a member |
| Points (sushi 2x) | 860 | 940 | 360 |
| Points by end of January (A, B only) | 1,370 | 820 | not a member |

**Most purchased item overall:** ramen, ordered 8 times.

## 💡 Insights

- **Ramen is the best seller** and the clear favorite of customers A and C.
- **Customer B visits most often** (6 days) but spends slightly less than A.
- **Customer C never joined** the loyalty program despite repeat ramen orders, which makes C a good target for a membership offer.
- The 2x first-week bonus noticeably boosts points for new members, which supports expanding the program.

---

## 📝 Notes & Assumptions

- Only A and B are loyalty members. Customer C is **not** added to `members`.
- Purchases on the join date count as **after** joining (`order_date >= join_date`).
- Ties are handled with `RANK()` / `DENSE_RANK()` instead of `ROW_NUMBER()`, so same-day orders are not dropped (for example, customer A's first order includes both curry and sushi).
- Points: $1 = 10 points, sushi = 2x. During the first week after joining (join date + 6 days), all items earn 2x. The two bonuses do not stack.
- `Order_id` (identity) was added to `sales` as a primary key.

## ▶️ How to Run

1. Install **SQL Server** and **SQL Server Management Studio** (or Azure Data Studio).
2. Create the `dannys_diner` schema and load the `sales`, `menu`, and `members` tables (the case study provides the setup script).
3. Open `dannysdineranalysis.sql` and run each query in order.

## 🛠️ Tools

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Window Functions](https://img.shields.io/badge/Window%20Functions-0A66C2?style=for-the-badge)
![CTEs](https://img.shields.io/badge/CTEs-444444?style=for-the-badge)

