------------------------------------------------------------------------------------------------------------------------
-----             Respondendo supostas perguntas de negócios usando a base de dados da Olist                       -----
------------------------------------------------------------------------------------------------------------------------

-- Quantos clientes distintos fizeram pedido?
SELECT COUNT(DISTINCT customer_id) 
FROM orders o;

-- Qual o número de clientes únicos por estado?
SELECT customer_state, COUNT(DISTINCT customer_id) AS qtd_clientes
FROM customer c
GROUP BY customer_state 
ORDER BY qtd_clientes DESC
LIMIT 10;

-- Quantos vendedores distintos estão cadastrados na base de dados?
SELECT COUNT(DISTINCT seller_id)
FROM sellers s;

-- Quantos vendedores distintos estão cadastrados por estado?
SELECT seller_state, COUNT(DISTINCT seller_id) AS qtd_vendedores
FROM sellers s 
GROUP BY seller_state 
ORDER BY qtd_vendedores DESC;

-- Quantos produtos estão cadastrados na base de dados?
SELECT COUNT(DISTINCT product_id) 
FROM products p;

-- Quantos produtos estão cadastrados por categoria?
SELECT product_category_name, COUNT(DISTINCT product_id) AS qtd_produtos
FROM products p
GROUP BY product_category_name
ORDER BY qtd_produtos DESC;

-- Quais os tipos de pagamentos existentes?
SELECT DISTINCT payment_type
FROM order_payments op;

-- Qual a quantidade de pedidos por tipo de pagamento?
SELECT payment_type, COUNT(op.order_id) AS qtd_pedidos
FROM order_payments op
GROUP BY payment_type
ORDER BY qtd_pedidos DESC;

-- Quais os tipos de status para um pedido?
SELECT DISTINCT order_status
FROM orders o;

-- Qual o maior e o menor valor de preço entre todos os pedidos?
SELECT MAX(price) AS maior_valor, MIN(price) AS menor_valor
FROM order_items oi;

-- Qual a categoria do produto mais caro?
SELECT p.product_category_name, p.product_id, oi.price
FROM order_items oi LEFT JOIN products p ON (p.product_id = oi.product_id)
WHERE price = (SELECT MAX(price) FROM order_items oi);

-- Qual a categoria do produto mais barato?
SELECT DISTINCT p.product_category_name, p.product_id, oi.price
FROM order_items oi LEFT JOIN products p ON (p.product_id = oi.product_id)
WHERE price = (SELECT MIN(price) FROM order_items oi);

-- Quantos clientes únicos tiveram seu pedidos com status de “processing”, “shipped” e “delivered”, 
-- feitos entre os dias 01 e 31 de Outubro de 2016. Mostrar o resultado somente se o número total de 
-- clientes for acima de 5.
SELECT order_status, COUNT(DISTINCT customer_id) AS qtd_clientes 
FROM orders o 
WHERE (order_status IN ('processing', 'shipped', 'delivered')) AND 
      (order_purchase_timestamp BETWEEN '2016-10-01' AND '2016-10-31')
GROUP BY order_status 
HAVING qtd_clientes > 5;

-- Gerar uma tabela de dados com 20 linhas, contendo as seguintes colunas: Id do pedido, status do pedido, 
-- id do produto, categoria do produto, avaliação do pedido, valor do pagamento, tipo do pagamento e
-- cidade do vendedor.
SELECT DISTINCT o.order_id, o.order_status, oi.product_id, p.product_category_name, or2.review_score, op.payment_value,
	op.payment_type, s.seller_city
FROM orders o LEFT JOIN order_items oi ON (oi.order_id = o.order_id)
			  LEFT JOIN products p ON (p.product_id = oi.product_id)
			  LEFT JOIN order_payments op ON (op.order_id = o.order_id)
			  LEFT JOIN order_reviews or2 ON (or2.order_id = o.order_id)
			  LEFT JOIN sellers s ON (s.seller_id = oi.seller_id)
			  LEFT JOIN geolocation g ON (g.geolocation_zip_code_prefix = s.seller_zip_code_prefix)
LIMIT 20;

-- Quais pedidos tem mais de 5 items?
SELECT o.order_id, COUNT(DISTINCT oi.product_id) AS qtd_produtos 
FROM orders o LEFT JOIN order_items oi ON (oi.order_id = o.order_id)
GROUP BY o.order_id 
HAVING qtd_produtos > 5;

-- Quais são os top 10 vendedores com mais clientes?
SELECT s.seller_id, COUNT(DISTINCT c.customer_id) AS qtd_clientes
FROM orders o LEFT JOIN order_items oi ON (oi.order_id = o.order_id)
			  LEFT JOIN sellers s ON (s.seller_id = oi.seller_id)
			  LEFT JOIN customer c ON (c.customer_id = o.customer_id)
GROUP BY s.seller_id 
ORDER BY qtd_clientes DESC 
LIMIT 10 ;

-- Crie uma consulta que calcule a quantidade de produtos para cada uma das categorias abaixo com base no preço:
-- Preço abaixo de 50 -> Categoria A
-- Preço entre 50 e 100 -> Categoria B
-- Preço entre 100 e 500 -> Categoria C
-- Preço entre 500 e 1500 -> Categoria D
-- Preço acima de 1500 -> Categoria E
WITH categoria_preco AS (
	SELECT oi.product_id, 
		(CASE
			WHEN price < 50 THEN 'categoria_A'
			WHEN price >=50 AND price < 100 THEN 'categoria_B'
			WHEN price >=100 AND price < 500 THEN 'categoria_C'
			WHEN price >= 500 AND price < 1500 THEN 'categoria_D'
			ELSE 'categoria_E'
		END) AS categoria_produto
	FROM order_items oi
)
SELECT categoria_produto, COUNT(DISTINCT product_id) AS qtd_produto
FROM categoria_preco cp
GROUP BY categoria_produto;

-- Selecione as seguintes categorias de produtos: livros técnicos, pet shop, pc gamer, tablets impressão imagem, 
-- fashion esports, perfumaria, telefonia, beleza saude, ferramentas jardim. Crie uma coluna com o novo preço da 
-- categoria, segundo os descontos abaixo, e outra coluna mostrando se a categoria sofreu ou não alteração de preço:
-- Livros técnicos - 10% de desconto
-- Pet shop - 20% de desconto
-- PC gamer - 50% de aumento
-- Tablets - 10% de aumento
-- Fashion Esports - 5% de aumento
SELECT p.product_id, p.product_category_name, oi.price,
	(CASE
		WHEN p.product_category_name = 'livros_tecnicos' THEN oi.price*0.9
		WHEN p.product_category_name = 'petshop' THEN oi.price*0.8
		WHEN p.product_category_name = 'pc_gamer' THEN oi.price*1.5
		WHEN p.product_category_name = 'tablets_impressao_imagem' THEN oi.price*1.1
		WHEN p.product_category_name = 'fashion_esporte' THEN oi.price*1.05
		ELSE oi.price
	END) AS novo_preco,
	(CASE
		WHEN p.product_category_name IN ('livros_tecnicos', 'petshop', 'pc_gamer', 'tablets_impressao_imagem', 
			'fashion_esporte') THEN 'alterado'
		ELSE 'normal'
	END) AS status
FROM order_items oi LEFT JOIN products p ON (p.product_id = oi.product_id) 
WHERE p.product_category_name IN ('livros_tecnicos', 'pet_shop', 'pc_gamer', 'tablets_impressao_imagem', 
	'fashion_esporte', 'perfumaria', 'telefonia', 'beleza_saude', 'ferramentas_jardim');

-- Qual o valor da média ponderada por mês das avaliações dos produtos que foram comprados a partir do 
-- dia 1 de Janeiro de 2018? Considere os pesos das respectivas notas das avaliações abaixo:
-- Nota 5 → Peso 0.2
-- Nota 4 → Peso 0.1
-- Nota 3 → Peso 0.3
-- Nota 2 → Peso 0.3
-- Nota 1 → Peso 0.1
-- Nota 0 → Peso 0.0
WITH tab_pesos AS (
	SELECT STRFTIME('%m', o.order_purchase_timestamp) AS mes,
		SUM(CASE 
				WHEN or2.review_score = 5 THEN or2.review_score*0.2
				WHEN or2.review_score = 4 THEN or2.review_score*0.1
				WHEN or2.review_score = 3 THEN or2.review_score*0.3
				WHEN or2.review_score = 2 THEN or2.review_score*0.3
				WHEN or2.review_score = 1 THEN or2.review_score*0.1
				ELSE or2.review_score*0
		    END) AS soma_notas_com_pesos,
		SUM(CASE
				WHEN or2.review_score = 5 THEN 0.2
				WHEN or2.review_score = 4 THEN 0.1
				WHEN or2.review_score = 3 THEN 0.3
				WHEN or2.review_score = 2 THEN 0.3
				WHEN or2.review_score = 1 THEN 0.1
				ELSE 0 
			END) AS soma_pesos
	FROM order_reviews or2 LEFT JOIN orders o ON (o.order_id = or2.order_id)
	WHERE o.order_purchase_timestamp >= '2018-01-01'
	GROUP BY mes
)
SELECT mes, soma_notas_com_pesos/soma_pesos AS media_ponderada
FROM tab_pesos;

-- Crie uma consulta que exiba a data da compra, o valor de cada venda e a média móvel dos últimos três valores de
-- venda, incluindo o valor atual.
SELECT o.order_purchase_timestamp, oi.price,
	AVG(oi.price) OVER (ORDER BY o.order_purchase_timestamp ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel 
FROM orders o LEFT JOIN order_items oi ON (oi.order_id = o.order_id);

-- Crie uma consulta que exiba o estado do cliente, a categoria, a quantidade de produtos vendidos e o percentual de
-- vendas em relação ao total vendido no estado.
WITH vendas AS (
	SELECT c.customer_state AS state, p.product_category_name AS categoria, COUNT(oi.product_id) AS produtos
	  FROM orders o LEFT JOIN order_items oi ON ( oi.order_id = o.order_id )
					LEFT JOIN products p ON ( p.product_id = oi.product_id )
					LEFT JOIN customer c ON ( c.customer_id = o.customer_id )
	  GROUP BY c.customer_state, p.product_category_name
	  HAVING p.product_category_name IS NOT NULL
)
SELECT state, categoria, produtos, 
	SUM(produtos) OVER (PARTITION BY state) AS total_vendas_estado,
	produtos*1.0/SUM(produtos) OVER (PARTITION BY state) AS percentual_vendas
FROM vendas v
ORDER BY state, percentual_vendas DESC;

-- Qual a quantidade de clientes para cada nível de estrelas de avaliação (5 estrelas, 4 estrelas...)?
WITH tab_avaliacao AS (
	SELECT o.customer_id AS clientes, or2.review_score AS avaliacao
    FROM orders o LEFT JOIN order_reviews or2 ON (or2.order_id = o.order_id)
)
SELECT avaliacao, COUNT(clientes) AS qtd_total_clientes
FROM tab_avaliacao 
GROUP BY avaliacao;

-- Identifique os quartis com base no total de pedidos por vendedor.
WITH vendas_vendedor AS (
	SELECT s.seller_id, COUNT(DISTINCT o.order_id) AS total_pedidos
	FROM orders o LEFT JOIN order_items oi ON (oi.order_id = o.order_id)
				  LEFT JOIN sellers s ON (s.seller_id = oi.seller_id)
	WHERE s.seller_id IS NOT NULL
	GROUP BY s.seller_id
)
SELECT seller_id, total_pedidos,
	NTILE(4) OVER (ORDER BY total_pedidos) AS quartil
FROM vendas_vendedor vv;