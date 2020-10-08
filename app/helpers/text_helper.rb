module TextHelper
  # Adds a "+" character with aria-hidden in front of a string
  def prefix_with_plus(str)
    content_tag('span', '+', 'aria-hidden': true) + ' ' + str
  end
end
