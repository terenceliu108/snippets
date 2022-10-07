//print leaves
static void printLeafNode(const string key, const json value, const vector<json>& path, void* param) { 
	ImGui::Text("%s: %s", key.c_str(), value.dump().c_str()); 
} 

//expand nodes
static void expandAllNodes(const string key, const json value, const vector<json>& path, void* param) { 
	ImGui::SetNextItemOpen(true, ImGuiCond_Once); 
}

//generate TreeNodes from nlohmann::json object
//takes one function pointer and pointer to its parameters to run on each leaf
//takes another function pointer and point ot its parameters to run on each node
//default functions are given (see above)
static void jsonToTreeNodes(	const json& obj, 
				void(leafFunc)(const string key, const json value, const vector<json>& path, void* leafParam) = printLeafNode, //func to run on leaf nodes
				void* leafParam = NULL, //leaf node function's default param
				void(nodeFunc)(const string key, const json value, const vector<json>& path, void* nodeParam) = expandAllNodes, //func to run on all nodes t). 
				void* nodeParam = NULL, //leaf node function's default param
				bool subsequentRun = false) {		//don't pass this argument for first call
	static std::vector<json> path;
	static int sequenceNumber = 0;		//we need this to give keys with the same name a unique label
	for (const auto& [key, value] : obj.items()) {
		if (value.is_array() or value.is_object()) {
			nodeFunc(key, value, path, nodeParam);
			if (ImGui::TreeNode((key + "##" + to_string(++sequenceNumber)).c_str())) { //## + sequence number is our unique label
				path.push_back(key);	//this can be used later to populate the a json_pointer
					jsonToTreeNodes(value, leafFunc, leafParam, nodeFunc, nodeParam); //recursive calls will continue to increment the sequence number
					ImGui::TreePop();
				path.pop_back();
			}
		} else {
			leafFunc(key, value, path, leafParam); //call our leaf node function
		}
	}
	if (!subsequentRun) sequenceNumber = 0;	//we have to reset this once the entire Tree has been iterated
}
