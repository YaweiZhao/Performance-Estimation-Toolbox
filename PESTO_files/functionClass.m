classdef functionClass < functionHandler
    properties (GetAccess=private)
        interp_list;
        list_size;
        interp_handler;
    end
    methods
        function obj=functionClass(InterpEval)
            obj.list_size=0;
            obj.interp_list=cell(0,1);
            assert(isa(InterpEval,'function_handle'),'Argument must be a handler');
            obj.interp_handler=InterpEval;
        end
        function obj=AddComponent(obj,x,g,f,spec)
            assert(strcmp(x.getType(),'Point') & strcmp(g.getType(),'Point') & strcmp(f.getType(),'Function value'),'Wrong type representation');
            obj.list_size=obj.list_size+1;
            if nargin > 4
                obj.interp_list{obj.list_size}.spec=spec;
            else
                obj.interp_list{obj.list_size}.spec='';
            end
            obj.interp_list{obj.list_size}.x=x;
            obj.interp_list{obj.list_size}.g=g;
            obj.interp_list{obj.list_size}.f=f;
        end
        function [x,f]=OptimalPoint(obj,tag)
            x=Point('Point');
            g=Point('Point',0);
            f=Point('Function value');
            if nargin < 2
                tag='optimum';
            end
            obj.AddComponent(x,g,f,tag);
        end
        function [x,f]=GetOptimalPoint(obj,tag)
            fprintf('GetOptimalPoint is deprecated, consider using OptimalPoint instead\n');
            if nargin ==2
                [x,f]=obj.OptimalPoint(tag);
            else
                [x,f]=obj.OptimalPoint();
            end
        end
        function [g, f]=oracle(obj,x,tag)
            assert(isa(x,'char') | isa(x,'Evaluable'),'Oracle call: x must either be a tag or a point');
            if nargin>=3
                assert(isa(tag,'char'),'Oracle call: second argument must be a tag (string)');
                spec=tag;
            else
                spec='';
            end
            found=0;
            if isa(x,'char')
                for i=1:obj.list_size
                    if strcmp(x,obj.interp_list{i}.spec)
                        g=obj.interp_list{i}.g;
                        f=obj.interp_list{i}.f;
                        found=1;
                        break;
                    end
                end
                if found~=1
                    assert(false,'Oracle: this tag does not match any previously evaluated point.')
                end
            else
                g=Point('Point');
                f=Point('Function value');
                obj.AddComponent(x,g,f,spec);
            end
        end
        function cons=GetInterp(obj)
            cons=[];
            for i=1:obj.list_size
                for j=1:obj.list_size
                    new_cons=obj.interp_handler(obj.interp_list{i},obj.interp_list{j});
                    if ~isempty(new_cons)
                        cons=cons+new_cons.Eval();
                    end
                end
            end
        end
        function obj3=plus(obj1,obj2)
            assert(isa(obj1,'functionClass') && isa(obj2,'functionClass'));
            obj3=CompositeFunction(obj1,obj2);
        end
        function disp(obj)
            fprintf('Function, %d interpolation points\n',obj.list_size);
        end
    end
end