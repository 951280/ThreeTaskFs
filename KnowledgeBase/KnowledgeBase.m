% @KnowledgeBase/KnowledgeBase.m

classdef KnowledgeBase < handle
    % KnowledgeBase 类：存储和管理共享的知识，即 IM 矩阵和 SV 向量。
    % 继承自 handle 类，确保所有任务共享同一个实例并对修改是可见的。
    
    properties
        IM                      % [Sparse Matrix] 交互矩阵 (Interaction Matrix)。IM(i, j) 表示特征 i 和 j 的协同优越性。
        SV                      % [Vector] 显著性向量 (Significance Vector)。SV(i) 表示特征 i 的单特征优越性。
        
        FeatureDomainIndices    % [Vector] 当前 IM/SV 所涵盖的特征在原始特征集中的索引。
        DomainSize              % [int] 当前特征域的大小 (即 length(SV) 或 size(IM, 1))。
        TotalFeatureCount       % [int] 原始数据中的总特征数量 N。
        
        IM_SV_InitValue         % [double] IM 和 SV 的初始/小常数值 (来自 config_parameters)。
    end
    
    methods
        function obj = KnowledgeBase(total_N, initial_domain_indices, init_value)
            % KnowledgeBase 构造函数
            %
            % 输入:
            %   total_N: 原始数据的总特征数量。
            %   initial_domain_indices: 初始 IM/SV 所覆盖的特征索引。
            %   init_value: IM/SV 的初始值 (小常数)。
            
            if nargin > 0
                obj.TotalFeatureCount = total_N;
                obj.IM_SV_InitValue = init_value;
                
                % 初始化知识库
                obj = obj.refreshDomain(initial_domain_indices);
            end
        end
        
        function obj = refreshDomain(obj, new_domain_indices)
            % REFRESHDOMAIN 刷新 IM 和 SV 的特征域。
            % (对应论文中“每 K 代执行一次刷新”的逻辑)
            %
            % 输入:
            %   new_domain_indices: 新的特征域索引 (例如：任务二、三当前精英解的特征交集 F1)。
            
            new_domain_indices = unique(new_domain_indices); % 确保索引唯一
            new_size = length(new_domain_indices);
            
            % --- 1. 准备新的 IM 和 SV ---
            new_IM = sparse(new_size, new_size);
            new_SV = ones(new_size, 1) * obj.IM_SV_InitValue;
            
            % --- 2. 迁移旧的知识 (保留历史 Top-M SV 和 Top-K IM) ---
            % 遍历新的域索引，查找它们是否在旧的域中存在
            
            if ~isempty(obj.FeatureDomainIndices) && ~isempty(obj.IM)
                % 旧域索引到新域索引的映射
                [~, new_idx, old_idx] = intersect(new_domain_indices, obj.FeatureDomainIndices);
                
                % 迁移 SV：将旧 SV 值复制到新 SV 的对应位置
                new_SV(new_idx) = obj.SV(old_idx);
                
                % 迁移 IM：将旧 IM 值复制到新 IM 的对应位置
                % IM 迁移需要处理稀疏矩阵的索引映射
                if ~isempty(old_idx)
                    for i = 1:length(old_idx)
                        for j = 1:length(old_idx)
                            % 假设 IM 是对称的，只处理 IM(i, j)
                            new_IM(new_idx(i), new_idx(j)) = obj.IM(old_idx(i), old_idx(j));
                        end
                    end
                end
                
                % 论文提到：保留历史中 top-M SV 高值与 top-K IM 并合入新矩阵
                % 此处逻辑已在迁移步骤中被涵盖。如果需要更复杂的融合，
                % 例如，将历史最高值进行额外的加权，可以在此添加逻辑。
            else
                 % 初始创建时，新特征域中未在历史中出现的特征，SV 初始化为小常数。
                 % 这一点已在 new_SV = ones(...) * init_value 中体现。
                 
                 % 对于初始的 IM/SV 域：
                 % 论文指出：取 LightGBM 与 Relief-F 的前若干特征交集。
                 % 这将在主程序中调用本构造函数前完成，传入 initial_domain_indices。
            end
            
            % --- 3. 更新对象属性 ---
            obj.FeatureDomainIndices = new_domain_indices;
            obj.DomainSize = new_size;
            obj.IM = new_IM;
            obj.SV = new_SV;
        end % refreshDomain
        
        % Note: updateIM_SV 方法 (Phase 3, Step 11) 将被单独编写在 KnowledgeTransfer 文件夹中，
        % 并作为 KnowledgeBase 对象的方法进行调用。
        
    end % methods
end % classdef