-- CATEGORIAS
CREATE TABLE fagroz.estoque_categorias (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL UNIQUE,
  descricao TEXT,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- FORNECEDORES
CREATE TABLE fagroz.estoque_fornecedores (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL UNIQUE,
  cnpj VARCHAR(18) UNIQUE NULL,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- SETORES
CREATE TABLE fagroz.estoque_setores (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL UNIQUE,
  sigla VARCHAR(20) NOT NULL UNIQUE,
  ativo BOOLEAN NOT NULL DEFAULT TRUE
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- MATERIAIS
-- status: Status ("Disponível / Estoque baixo / Sem estoque") é derivado (view ou generated column), não coluna editável.
CREATE TABLE fagroz.estoque_materiais (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nome VARCHAR(255) NOT NULL UNIQUE,
  categoria_id INT UNSIGNED NOT NULL,
  -- Coluna para salvar a quantidade no estoque central e não precisar varrer a tabela que armazena os materiais por setor para saber a quantidade total (Verificar se é isso)
  estoque_central INT UNSIGNED NOT NULL DEFAULT 0,
  -- Coluna para salvar a quantidade mínima que deve ter no estoque  central e fazer condicional para avisar quando estiver abaixo do mínimo (Verificar se é isso)
  estoque_minimo INT UNSIGNED NOT NULL DEFAULT 0,
  ativo BOOLEAN NOT NULL DEFAULT TRUE,
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

  CONSTRAINT fk_materiais_categoria FOREIGN KEY (categoria_id)
    REFERENCES fagroz.estoque_categorias(id)
     ON DELETE RESTRICT,

  CONSTRAINT chk_materiais_estoque_central
    CHECK (estoque_central >= 0),

  CONSTRAINT chk_materiais_estoque_minimo
    CHECK (estoque_minimo >= 0)
);

-- POSSES
CREATE TABLE fagroz.estoque_posses (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  material_id INT UNSIGNED NOT NULL,
  setor_id INT UNSIGNED NOT NULL,
  quantidade INT UNSIGNED NOT NULL DEFAULT 0,
  ultima_saida TIMESTAMP NULL,

  CONSTRAINT fk_posses_material
    FOREIGN KEY (material_id)
    REFERENCES fagroz.estoque_materiais(id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_posses_setor
    FOREIGN KEY (setor_id)
    REFERENCES fagroz.estoque_setores(id)
    ON DELETE RESTRICT,

  CONSTRAINT uq_posses_material_setor
    UNIQUE (material_id, setor_id)
);

-- MOVIMENTAÇÕES
CREATE TABLE fagroz.estoque_movimentacoes (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  data TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  material_id INT UNSIGNED NOT NULL,
  tipo ENUM('entrada', 'saida') NOT NULL,
  quantidade INT UNSIGNED NOT NULL,
  setor_id INT UNSIGNED NULL,
  responsavel_id INT UNSIGNED NOT NULL,
  pedido_id INT UNSIGNED NULL,
  observacao TEXT NULL,
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

  CONSTRAINT chk_movimentacoes_quantidade
    CHECK (quantidade > 0),

  CONSTRAINT fk_movimentacoes_material
    FOREIGN KEY (material_id)
    REFERENCES fagroz.estoque_materiais(id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_movimentacoes_setor
    FOREIGN KEY (setor_id)
    REFERENCES fagroz.estoque_setores(id)
    ON DELETE RESTRICT,

  INDEX idx_movimentacoes_material (material_id),
  INDEX idx_movimentacoes_setor (setor_id),
  INDEX idx_movimentacoes_data (data),
  INDEX idx_movimentacoes_tipo (tipo)
);

-- PEDIDOS
CREATE TABLE fagroz.estoque_pedidos (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  numero VARCHAR(100) NOT NULL UNIQUE,
  data DATE NOT NULL,
  fornecedor_id INT UNSIGNED NOT NULL,
  solicitante_id INT UNSIGNED NOT NULL,
  situacao ENUM(
    'em_aprovacao',
    'aprovado',
    'recebido',
    'parcialmente_recebido',
    'cancelado'
  ) NOT NULL DEFAULT 'em_aprovacao',
  -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  CONSTRAINT fk_pedidos_fornecedor
    FOREIGN KEY (fornecedor_id)
    REFERENCES fagroz.estoque_fornecedores(id)
    ON DELETE RESTRICT,

  INDEX idx_pedidos_fornecedor (fornecedor_id),
  INDEX idx_pedidos_solicitante (solicitante_id),
  INDEX idx_pedidos_data (data),
  INDEX idx_pedidos_situacao (situacao)
);

--  PEDIDOS_ITENS
CREATE TABLE fagroz.estoque_pedido_itens (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT UNSIGNED NOT NULL,
    material_id INT UNSIGNED NOT NULL,
    quantidade INT UNSIGNED NOT NULL,
    valor_unitario DECIMAL(14,2) NOT NULL,
    -- Coluna para salvar a quantidade recebida do item do pedido, para controlar se o pedido foi totalmente ou parcialmente recebido (Verificar se é isso)
    quantidade_recebida INT UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT chk_pedido_itens_quantidade
      CHECK (quantidade > 0),

    CONSTRAINT chk_pedido_itens_valor_unitario
      CHECK (valor_unitario >= 0),

    CONSTRAINT chk_pedido_itens_quantidade_recebida
      CHECK (
        quantidade_recebida >= 0
          AND quantidade_recebida <= quantidade
      ),

    CONSTRAINT fk_pedido_itens_pedido
      FOREIGN KEY (pedido_id)
      REFERENCES fagroz.estoque_pedidos(id)
      ON DELETE CASCADE,

    CONSTRAINT fk_pedido_itens_material
      FOREIGN KEY (material_id)
      REFERENCES fagroz.estoque_materiais(id),

    CONSTRAINT uq_pedido_itens_pedido_material
        UNIQUE (pedido_id, material_id),

    INDEX idx_pedido_itens_pedido (pedido_id),
    INDEX idx_pedido_itens_material (material_id)
);

-- GASTOS
CREATE TABLE fagroz.estoque_gastos (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  data DATE NOT NULL,
  material_id INT UNSIGNED NOT NULL,
  pedido_id INT UNSIGNED NOT NULL,
  movimentacao_id INT UNSIGNED NOT NULL,
  quantidade INT UNSIGNED NOT NULL,
  valor_total DECIMAL(14,2) NOT NULL,

  CONSTRAINT chk_gastos_quantidade
      CHECK (quantidade > 0),

  CONSTRAINT chk_gastos_valor_total
      CHECK (valor_total >= 0),

  CONSTRAINT fk_gastos_material
      FOREIGN KEY (material_id)
      REFERENCES fagroz.estoque_materiais(id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_gastos_pedido
      FOREIGN KEY (pedido_id)
      REFERENCES fagroz.estoque_pedidos(id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_gastos_movimentacao
      FOREIGN KEY (movimentacao_id)
      REFERENCES fagroz.estoque_movimentacoes(id)
      ON DELETE RESTRICT,

  INDEX idx_gastos_material (material_id),
  INDEX idx_gastos_pedido (pedido_id),
  INDEX idx_gastos_movimentacao (movimentacao_id),
  INDEX idx_gastos_data (data)
);

-- USUARIOS
CREATE TABLE fagroz.estoque_usuarios (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    cargo VARCHAR(255) NULL,
    role ENUM(
      'admin',
      'almoxarife',
      'leitor'
    ) NOT NULL DEFAULT 'leitor',
    ativo BOOLEAN NOT NULL DEFAULT TRUE
    -- Se usar o prisma vai criar automaticamente
  -- createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);