class ConfigurableArray < SimpleDelegator

  def insert_before(new_element, element)
    idx = index(element) || -1
    insert(idx, new_element)
  end

  def insert_after(new_element, element)
    idx = index(element) || -2
    insert(idx + 1, new_element)
  end

end
